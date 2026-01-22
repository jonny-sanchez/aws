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
