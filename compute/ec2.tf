# Primary Network Interfaces (ENI)
resource "aws_network_interface" "ec2_eni" {
  for_each = local.config.ec2_instances
  
  subnet_id       = each.value.use_elastic_ip ? local.config.public_subnets[0] : local.config.private_subnets[0]
  security_groups = [aws_security_group.ec2_sg[each.key].id]

  tags = {
    Name = "eni-${each.key}-${local.workspace_suffix}"
  }
}

# Instancias EC2
resource "aws_instance" "ec2" {
  for_each = local.config.ec2_instances
  
  ami                    = each.value.ami_id
  instance_type          = each.value.instance_type
  subnet_id              = each.value.use_elastic_ip ? local.config.public_subnets[0] : local.config.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg[each.key].id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile[each.key].name
  key_name               = aws_key_pair.ec2_key_pair[each.key].key_name
  
  root_block_device {
    volume_size = each.value.storage_size
    volume_type = "gp3"
  }

  tags = {
    Name = "ec2-${each.key}-${local.workspace_suffix}"
  }
}
