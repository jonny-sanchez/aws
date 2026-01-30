data "aws_region" "current" {}

data "aws_subnets" "data" {
  filter {
    name   = "vpc-id"
    values = [local.config.utility_vpc]
  }
  tags = {
    "Tier" = "private"
  }
}

