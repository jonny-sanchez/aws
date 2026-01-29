import boto3
import os
import time

# Define the set of tags to filter resources. Adjust keys/values as needed.
REQUIRED_TAGS = {
    "Scheduler": "true"
}

# Initialize boto3 clients
rds_client = boto3.client('rds')
ec2_client = boto3.client('ec2')

def resource_has_required_tags(resource_tags, required_tags=REQUIRED_TAGS):
    """
    Check if the given resource tags (list of dicts) contain all the required tags.
    Example resource_tags: [{'Key': 'Environment', 'Value': 'Prod'}, ...]
    """
    for key, value in required_tags.items():
        if not any(tag.get('key') == key and tag.get('value') == value for tag in resource_tags):
            if not any(tag.get('Key') == key and tag.get('Value') == value for tag in resource_tags):
                return False
    return True

def process_rds_instances(action):
    """
    Retrieve all RDS instances, filter by required tags, and then start or stop them.
    Returns list of RDS instance IDs that were started.
    """
    started_instances = []
    response = rds_client.describe_db_instances()
    db_instances = response.get('DBInstances', [])

    for db in db_instances:
        db_id = db.get('DBInstanceIdentifier')
        db_arn = db.get('DBInstanceArn')
        # Retrieve tags for the RDS instance
        tags_response = rds_client.list_tags_for_resource(ResourceName=db_arn)
        tags = tags_response.get('TagList', [])
        print(f"Tags for RDS instance {db_id}: {tags}")
        
        if resource_has_required_tags(tags):
            if action == 'start':
                print(f"Starting RDS instance: {db_id}")
                rds_client.start_db_instance(DBInstanceIdentifier=db_id)
                started_instances.append(db_id)
            elif action == 'stop':
                print(f"Stopping RDS instance: {db_id}")
                rds_client.stop_db_instance(DBInstanceIdentifier=db_id)
            else:
                print(f"Unknown action '{action}' for RDS instance {db_id}")
    
    return started_instances

def wait_for_rds_instances(db_instance_ids, timeout_seconds=600):
    """
    Wait for RDS instances to become available.
    Timeout after the specified number of seconds (default 10 minutes).
    Returns True if all instances are available, False if timeout occurred.
    """
    if not db_instance_ids:
        print("No RDS instances to wait for.")
        return True
    
    start_time = time.time()
    print(f"Waiting for RDS instances to be available: {db_instance_ids}")
    print(f"Timeout set to {timeout_seconds} seconds ({timeout_seconds/60} minutes)")
    
    while True:
        elapsed_time = time.time() - start_time
        
        if elapsed_time > timeout_seconds:
            print(f"Timeout reached after {elapsed_time:.2f} seconds. Proceeding anyway.")
            return False
        
        # Check status of all instances
        all_available = True
        for db_id in db_instance_ids:
            try:
                response = rds_client.describe_db_instances(DBInstanceIdentifier=db_id)
                db_instance = response['DBInstances'][0]
                status = db_instance.get('DBInstanceStatus')
                print(f"RDS instance {db_id} status: {status} (elapsed: {elapsed_time:.2f}s)")
                
                if status != 'available':
                    all_available = False
            except Exception as e:
                print(f"Error checking RDS instance {db_id}: {str(e)}")
                all_available = False
        
        if all_available:
            print(f"All RDS instances are available after {elapsed_time:.2f} seconds")
            return True
        
        # Wait 15 seconds before checking again
        print("RDS instances not yet available. Waiting 15 seconds before retry...")
        time.sleep(15)


def process_ec2_instances(action):
    """
    Retrieve all EC2 instances, filter by required tags, and then start or stop them.
    """
    response = ec2_client.describe_instances()
    
    for reservation in response.get('Reservations', []):
        for instance in reservation.get('Instances', []):
            instance_id = instance.get('InstanceId')
            tags = instance.get('Tags', [])
            print(f"Tags for EC2 instance {instance_id}: {tags}")
            
            if resource_has_required_tags(tags):
                if action == 'start':
                    print(f"Starting EC2 instance: {instance_id}")
                    ec2_client.start_instances(InstanceIds=[instance_id])
                elif action == 'stop':
                    print(f"Stopping EC2 instance: {instance_id}")
                    ec2_client.stop_instances(InstanceIds=[instance_id])
                else:
                    print(f"Unknown action '{action}' for EC2 instance {instance_id}")
        

def lambda_handler(event, context):
    """
    Lambda entry point.
    
    The event should include:
    - 'action' key with value 'start' or 'stop'
    - 'resources' key with value 'rds', 'ec2', or 'both' (default: 'both')
    
    Examples: 
    - { "action": "start", "resources": "rds" } - Only start RDS instances
    - { "action": "start", "resources": "ec2" } - Only start EC2 instances
    - { "action": "stop", "resources": "both" } - Stop both RDS and EC2
    """
    action = event.get('action')
    resources = event.get('resources', 'both')
    
    if action not in ['start', 'stop']:
        raise ValueError("Event must contain an 'action' key with value 'start' or 'stop'.")
    
    if resources not in ['rds', 'ec2', 'both']:
        raise ValueError("Event 'resources' key must be 'rds', 'ec2', or 'both'.")

    print(f"Received action: {action}, resources: {resources}")

    started_rds_instances = []
    
    # Process RDS instances if requested
    if resources in ['rds', 'both']:
        print(f"Processing RDS instances...")
        started_rds_instances = process_rds_instances(action)
    
    # Process EC2 instances if requested
    if resources in ['ec2', 'both']:
        # If starting EC2 and we also started RDS in this same invocation, wait for RDS
        if action == 'start' and resources == 'both' and started_rds_instances:
            print(f"Waiting for {len(started_rds_instances)} RDS instance(s) to be ready before starting EC2 instances...")
            wait_for_rds_instances(started_rds_instances, timeout_seconds=600)
        
        print(f"Processing EC2 instances...")
        process_ec2_instances(action)
    
    return {
        'statusCode': 200,
        'body': f"Action '{action}' executed for {resources}."
    }
