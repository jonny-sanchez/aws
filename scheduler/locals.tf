locals {
  config = yamldecode(file("${path.module}/config/${terraform.workspace}.yaml"))
}