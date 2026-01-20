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
