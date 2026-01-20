locals {
  validate = terraform.workspace == "default" ? throw("Default workspace is not allowed") : true
  config   = yamldecode(file("${path.module}/config/values.yaml"))

  # We create these maps because terraform can't do double loops
  permission_set_policies = merge({}, [for kps, ps in local.config.permission_sets : { for policy in ps.aws_managed_policies : format("%s/${index(ps.aws_managed_policies, policy)}", kps) => policy }]...)
  account_assignments     = merge({}, [for kactt, acct in local.config.account_assignments : { for assignment in acct : format("%s/${index(acct, assignment)}", kactt) => assignment }]...)
  group_assignments       = merge({}, [for ku, user in local.config.users : { for group in user.groups : format("%s/${index(user.groups, group)}", ku) => group }]...)
}