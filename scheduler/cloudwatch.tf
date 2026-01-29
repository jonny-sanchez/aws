# EventBridge rule to start RDS instances (30 min before EC2 instances)
resource "aws_cloudwatch_event_rule" "scheduler_rds_on_rule" {
  name                = "${local.config.environment}-scheduler-rule-rds-on"
  description         = "EventBridge rule to start RDS instances 30 min before EC2 instances"
  schedule_expression = local.config.on_schedule_expression_rds
}

resource "aws_cloudwatch_event_target" "scheduler_lambda_target_rds_on" {
  rule      = aws_cloudwatch_event_rule.scheduler_rds_on_rule.name
  target_id = "${local.config.environment}-scheduler-target-rds-on"
  arn       = aws_lambda_function.manage_resources.arn
  input = jsonencode({
    action    = "start"
    resources = "rds"
  })
}

# EventBridge rule to start EC2 instances (30 min after RDS)
resource "aws_cloudwatch_event_rule" "scheduler_ec2_on_rule" {
  name                = "${local.config.environment}-scheduler-rule-ec2-on"
  description         = "EventBridge rule to start EC2 instances after RDS is ready"
  schedule_expression = local.config.on_schedule_expression_ec2
}

resource "aws_cloudwatch_event_target" "scheduler_lambda_target_ec2_on" {
  rule      = aws_cloudwatch_event_rule.scheduler_ec2_on_rule.name
  target_id = "${local.config.environment}-scheduler-target-ec2-on"
  arn       = aws_lambda_function.manage_resources.arn
  input = jsonencode({
    action    = "start"
    resources = "ec2"
  })
}

# EventBridge rule to stop both RDS and EC2 instances
resource "aws_cloudwatch_event_rule" "scheduler_off_rule" {
  name                = "${local.config.environment}-scheduler-rule-off"
  description         = "EventBridge rule to stop both RDS instances and EC2 instances"
  schedule_expression = local.config.off_schedule_expression
}

resource "aws_cloudwatch_event_target" "scheduler_lambda_target_off" {
  rule      = aws_cloudwatch_event_rule.scheduler_off_rule.name
  target_id = "${local.config.environment}-scheduler-target-off"
  arn       = aws_lambda_function.manage_resources.arn
  input = jsonencode({
    action    = "stop"
    resources = "both"
  })
}