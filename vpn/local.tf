locals {
  validate = terraform.workspace == "default" ? throw("Default workspace is not allowed") : true
  config   = yamldecode(file("${path.module}/config/${terraform.workspace}.yaml"))
  
  identifier = "${local.config.identifier}-vpn"
}
