locals {

  config = yamldecode(file("${path.module}/config/${terraform.workspace}.yaml"))

  identifier = "${local.config.identifier}-${terraform.workspace}"

  tags = merge(tomap({
    Env = terraform.workspace
  }), local.config.tags)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  create_vpc = local.config.vpc.create_vpc

  name = local.identifier
  cidr = local.config.vpc.cidr

  azs             = local.config.vpc.azs
  private_subnets = local.config.vpc.private_subnets
  public_subnets  = local.config.vpc.public_subnets
  intra_subnets   = local.config.vpc.intra_subnets

  enable_nat_gateway = local.config.vpc.enable_nat_gateway
  enable_vpn_gateway = local.config.vpc.enable_vpn_gateway

  single_nat_gateway     = local.config.vpc.single_nat_gateway
  one_nat_gateway_per_az = local.config.vpc.one_nat_gateway_per_az

  create_flow_log_cloudwatch_iam_role  = local.config.vpc.create_flow_log_cloudwatch_iam_role
  create_flow_log_cloudwatch_log_group = local.config.vpc.create_flow_log_cloudwatch_log_group

  enable_flow_log      = local.config.vpc.enable_flow_log
  flow_log_file_format = local.config.vpc.flow_log_file_format

  public_subnet_tags = {
    "Tier" = "public"
  }

  private_subnet_tags = {
    "Tier" = "private"
  }

  intra_subnet_tags = {
    "Tier" = "intra"
  }

  tags = local.tags
}
