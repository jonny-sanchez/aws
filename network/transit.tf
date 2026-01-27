##############################################
# Network accounts
##############################################

module "transit_gateway" {
  count = local.config.transit.network.create ? 1 : 0
  source  = "terraform-aws-modules/transit-gateway/aws"
  version = "3.1.0"

  name        = local.identifier
  description = "Transit Gateway for connection"

  enable_auto_accept_shared_attachments = local.config.transit.network.auto_accept_attachments 

  share_tgw                = local.config.transit.network.share_tgw
  ram_allow_external_principals = local.config.transit.network.ram_external_principals
  
  ram_principals = local.config.transit.network.ram_principals

  enable_default_route_table_association = true
  enable_default_route_table_propagation = true

  tags = local.tags
}

resource "aws_ec2_transit_gateway_vpc_attachment" "network" {
  count = local.config.transit.network.create ? 1 : 0
  subnet_ids         = module.vpc.private_subnets 
  transit_gateway_id = module.transit_gateway[0].ec2_transit_gateway_id
  vpc_id             = module.vpc.vpc_id

  dns_support = "enable"
  
  tags = local.tags
}


resource "aws_route" "network_to_customer" {
  for_each = toset(local.config.transit.network.routes)
  # The Route Table ID of your Private Subnets in the Network Account
  route_table_id = module.vpc.private_route_table_ids[0]

  # The IP Range of the CUSTOMER account
  destination_cidr_block = each.value

  # Send it to the TGW created by the module
  transit_gateway_id = module.transit_gateway[0].ec2_transit_gateway_id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.network[0]
  ]
}

##############################################
# Consumer accounts
##############################################

# # 1. Get the data of the shared TGW (It must be shared via RAM first!)
data "aws_ec2_transit_gateway" "shared_tgw" {
  filter {
    name   = "owner-id"
    values = [local.config.transit.customer.owner]
  }
  
  # Optional: Filter by state to ensure it's available
  filter {
    name   = "state"
    values = ["available"]
  }
}

# 2. Create the Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count = local.config.transit.customer.create ? 1 : 0
  subnet_ids         = [module.vpc.private_subnets[0],module.vpc.public_subnets[1], module.vpc.intra_subnets[2]] # Subnets
  transit_gateway_id = data.aws_ec2_transit_gateway.shared_tgw.id
  vpc_id             = module.vpc.vpc_id

  dns_support = "enable"
  
  tags = local.tags
}

# 3. CRITICAL: Update VPC Route Tables
resource "aws_route" "send_to_tgw" {
  count = local.config.transit.customer.create ? 1 : 0
  route_table_id         = module.vpc.private_route_table_ids[0] # Your private subnet route table
  destination_cidr_block = local.config.transit.customer.route   # The CIDR of the OTHER account's network
  transit_gateway_id     = data.aws_ec2_transit_gateway.shared_tgw.id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.this[0]
  ]
}

resource "aws_route" "send_to_tgw_public" {
  count = local.config.transit.customer.create ? 1 : 0
  route_table_id         = module.vpc.public_route_table_ids[0] # Your private subnet route table
  destination_cidr_block = local.config.transit.customer.route   # The CIDR of the OTHER account's network
  transit_gateway_id     = data.aws_ec2_transit_gateway.shared_tgw.id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.this[0]
  ]
}

resource "aws_route" "send_to_tgw_intra" {
  count = local.config.transit.customer.create ? 1 : 0
  route_table_id         = module.vpc.intra_route_table_ids[0] # Your private subnet route table
  destination_cidr_block = local.config.transit.customer.route   # The CIDR of the OTHER account's network
  transit_gateway_id     = data.aws_ec2_transit_gateway.shared_tgw.id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.this[0]
  ]
}