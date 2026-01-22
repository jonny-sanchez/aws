resource "aws_identitystore_group" "this" {
  for_each = local.config.groups

  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
  display_name      = each.key
  description       = lookup(each.value, "description", null)
}

resource "aws_ssoadmin_permission_set" "this" {
  for_each = local.config.permission_sets

  name             = each.key
  description      = each.value.description
  instance_arn     = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  session_duration = each.value.session_duration
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = local.permission_set_policies

  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  managed_policy_arn = each.value
  permission_set_arn = aws_ssoadmin_permission_set.this[split("/", each.key)[0]].arn

  depends_on = [
    aws_ssoadmin_permission_set.this
  ]
}

resource "aws_ssoadmin_permission_set_inline_policy" "this" {
  for_each = { for key, value in local.config.permission_sets : key => value if contains(keys(value), "inline_policy") }

  inline_policy      = each.value.inline_policy
  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn

  depends_on = [
    aws_ssoadmin_permission_set.this
  ]
}

resource "aws_ssoadmin_account_assignment" "this" {
  for_each = local.account_assignments

  instance_arn       = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.permission_set].arn

  principal_id   = aws_identitystore_group.this[each.value.group].group_id
  principal_type = "GROUP"

  target_id   = split("/", each.key)[0]
  target_type = "AWS_ACCOUNT"

  depends_on = [
    aws_ssoadmin_permission_set.this,
    aws_identitystore_group.this
  ]
}

resource "aws_identitystore_user" "this" {
  for_each = local.config.users

  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  display_name = each.key
  user_name    = each.key

  name {
    given_name  = each.value.first_name
    family_name = each.value.last_name
  }

  emails {
    value   = each.key
    type    = "work"
    primary = true
  }
}

resource "aws_identitystore_group_membership" "this" {
  for_each = local.group_assignments

  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
  group_id          = aws_identitystore_group.this[local.config.users[split("/", each.key)[0]].groups[split("/", each.key)[1]]].group_id
  member_id         = aws_identitystore_user.this[split("/", each.key)[0]].user_id

  depends_on = [
    aws_identitystore_user.this,
    aws_identitystore_group.this
  ]
}
