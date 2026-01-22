# IAM Role para instancias EC2 con permisos de SSM
resource "aws_iam_role" "ec2_ssm_role" {
  for_each = local.config.ec2_instances
  
  name = "ec2-ssm-role-${each.key}-${local.workspace_suffix}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Adjuntar política de SSM al rol
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  for_each = local.config.ec2_instances
  
  role       = aws_iam_role.ec2_ssm_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile para asociar el rol a la instancia EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  for_each = local.config.ec2_instances
  
  name = "ec2-profile-${each.key}-${local.workspace_suffix}"
  role = aws_iam_role.ec2_ssm_role[each.key].name
}

# Security Groups
resource "aws_security_group" "ec2_sg" {
  for_each = local.config.ec2_instances
  
  name        = "sg-${each.key}-${local.workspace_suffix}"
  description = "Security group for ${each.key}"
  vpc_id      = local.config.vpc_id

  tags = {
    Name = "sg-${each.key}-${local.workspace_suffix}"
  }
}

# Reglas de ingreso para Security Groups
resource "aws_vpc_security_group_ingress_rule" "ingress" {
  for_each = {
    for item in flatten([
      for instance_key, instance in local.config.ec2_instances : [
        for idx, rule in instance.ingress_rules : {
          key         = "${instance_key}-ingress-${idx}"
          instance_key = instance_key
          rule        = rule
        }
      ]
    ]) : item.key => item
  }
  
  security_group_id = aws_security_group.ec2_sg[each.value.instance_key].id
  description       = each.value.rule.description
  from_port         = each.value.rule.from_port
  to_port           = each.value.rule.to_port
  ip_protocol       = each.value.rule.protocol
  cidr_ipv4         = each.value.rule.cidr_blocks[0]

  tags = {
    Name = "${each.value.instance_key}-ingress-${each.value.rule.from_port}"
  }
}

# Reglas de egreso para Security Groups
resource "aws_vpc_security_group_egress_rule" "egress" {
  for_each = {
    for item in flatten([
      for instance_key, instance in local.config.ec2_instances : [
        for idx, rule in instance.egress_rules : {
          key         = "${instance_key}-egress-${idx}"
          instance_key = instance_key
          rule        = rule
        }
      ]
    ]) : item.key => item
  }
  
  security_group_id = aws_security_group.ec2_sg[each.value.instance_key].id
  description       = each.value.rule.description
  from_port         = each.value.rule.from_port
  to_port           = each.value.rule.to_port
  ip_protocol       = each.value.rule.protocol
  cidr_ipv4         = each.value.rule.cidr_blocks[0]

  tags = {
    Name = "${each.value.instance_key}-egress-${each.value.rule.from_port}"
  }
}

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
  
  ami                  = each.value.ami_id
  instance_type        = each.value.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_profile[each.key].name
  
  root_block_device {
    volume_size = each.value.storage_size
    volume_type = "gp3"
  }

  tags = {
    Name = "ec2-${each.key}-${local.workspace_suffix}"
  }

  lifecycle {
    ignore_changes = [network_interface]
  }
}

# Adjuntar ENI a instancia EC2
resource "aws_network_interface_attachment" "ec2_eni_attachment" {
  for_each = local.config.ec2_instances
  
  instance_id          = aws_instance.ec2[each.key].id
  network_interface_id = aws_network_interface.ec2_eni[each.key].id
  device_index         = 0
}

# Elastic IPs (solo para instancias que lo requieren)
resource "aws_eip" "ec2_eip" {
  for_each = {
    for key, instance in local.config.ec2_instances : key => instance
    if instance.use_elastic_ip
  }
  
  domain = "vpc"

  tags = {
    Name = "eip-${each.key}-${local.workspace_suffix}"
  }
}

# Asociar EIP con ENI
resource "aws_eip_association" "ec2_eip_assoc" {
  for_each = {
    for key, instance in local.config.ec2_instances : key => instance
    if instance.use_elastic_ip
  }
  
  allocation_id        = aws_eip.ec2_eip[each.key].id
  network_interface_id = aws_network_interface.ec2_eni[each.key].id
}
