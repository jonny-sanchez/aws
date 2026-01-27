output "ec2_instances" {
  description = "Información de las instancias EC2 creadas"
  value = {
    for key, instance in aws_instance.ec2 : key => {
      id                = instance.id
      private_ip        = instance.private_ip
      security_group_id = aws_security_group.ec2_sg[key].id
      iam_role          = aws_iam_role.ec2_ssm_role[key].name
      subnet_id         = instance.subnet_id
      key_name          = aws_key_pair.ec2_key_pair[key].key_name
      key_file          = "${path.module}/keys/${key}-${local.workspace_suffix}.pem"
    }
  }
}

output "elastic_ips" {
  description = "Elastic IPs asignadas"
  value = {
    for key, eip in aws_eip.ec2_eip : key => {
      public_ip   = eip.public_ip
      instance_id = eip.instance
    }
  }
}

output "security_groups" {
  description = "Security Groups creados"
  value = {
    for key, sg in aws_security_group.ec2_sg : key => {
      id   = sg.id
      name = sg.name
    }
  }
}
