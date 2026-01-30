# Elastic IPs (solo para instancias que lo requieren)
resource "aws_eip" "ec2_eip" {
  for_each = {
    for key, instance in local.config.ec2_instances : key => instance
    if instance.use_elastic_ip
  }
  
  instance = aws_instance.ec2[each.key].id
  domain   = "vpc"

  tags = {
    Name = "eip-${each.key}-${local.workspace_suffix}"
  }
}
