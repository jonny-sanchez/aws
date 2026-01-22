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
