# TLS Private Keys for EC2 instances
resource "tls_private_key" "ec2_key" {
  for_each = local.config.ec2_instances
  
  algorithm = "RSA"
  rsa_bits  = 4096
}

# AWS Key Pairs
resource "aws_key_pair" "ec2_key_pair" {
  for_each = local.config.ec2_instances
  
  key_name   = "ec2-key-${each.key}-${local.workspace_suffix}"
  public_key = tls_private_key.ec2_key[each.key].public_key_openssh

  tags = {
    Name = "ec2-key-${each.key}-${local.workspace_suffix}"
  }
}

resource "aws_ssm_parameter" "ec2_key_param" {
  for_each = local.config.ec2_instances
  
  name        = "/${local.workspace_suffix}/ec2/${each.key}/private_key"
  description = "Private key for EC2 instance ${each.key} in ${local.workspace_suffix} environment"
  type        = "SecureString"
  value       = tls_private_key.ec2_key[each.key].private_key_pem

  tags = {
    Name = "ssm-ec2-key-${each.key}-${local.workspace_suffix}"
  }
}