module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases = ["alias/${local.identifier}"]

  key_statements = [
    {
      sid = "CloudWatchLogs"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${data.aws_region.current.id}.amazonaws.com"]
        }
      ]
    }
  ]
}

module "cloudwatch_log-group" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.6.0"

  kms_key_id        = module.kms.key_arn
  retention_in_days = 90
  name              = local.identifier
}

resource "aws_security_group" "this" {
  name        = local.identifier
  description = "AWS Client VPN Security Group"
  vpc_id      = local.config.utility_vpc
}

resource "aws_vpc_security_group_ingress_rule" "allow" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_ec2_client_vpn_endpoint" "this" {
  description            = local.identifier
  server_certificate_arn = local.config.vpn_certificate_arn
  self_service_portal    = "enabled"
  client_cidr_block      = local.config.client_vpn_cidr
  transport_protocol     = "tcp"
  split_tunnel           = true
  security_group_ids     = [aws_security_group.this.id]
  vpc_id                 = local.config.utility_vpc

  authentication_options {
    self_service_saml_provider_arn = local.config.self_service_saml_provider_arn
    saml_provider_arn              = local.config.saml_provider_arn
    type                           = "federated-authentication"
  }

  connection_log_options {
    cloudwatch_log_group = module.cloudwatch_log-group.cloudwatch_log_group_name
    enabled              = true
  }
}

resource "aws_ec2_client_vpn_network_association" "data" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  subnet_id              = data.aws_subnets.data.ids[0]
}

resource "aws_ec2_client_vpn_route" "this" {
  for_each = { for entry in flatten([
    for k, conn in try(local.config.attached_networks, {}) : [
      for cidr in conn.vpc_cidr : {
        key                    = "${k}-${cidr}"
        destination_cidr_block = cidr
      }
    ]
  ]) : entry.key => entry }

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  destination_cidr_block = each.value.destination_cidr_block
  target_vpc_subnet_id   = data.aws_subnets.data.ids[0]
  description            = each.key
}

resource "aws_ec2_client_vpn_authorization_rule" "authorization_rules" {
  for_each = { for entry in flatten([
    for net_name, net_data in try(local.config.attached_networks, {}) : [
      for cidr in net_data.vpc_cidr : [
        for group in net_data.groups_with_access : {
          key               = "${net_name}-${cidr}-${group}"
          target_vpc        = net_name
          cidr              = cidr
          group_with_access = group
        }
      ]
    ]
  ]) : entry.key => entry }

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = each.value.cidr
  access_group_id        = each.value.group_with_access
}
