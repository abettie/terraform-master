# IAM Identity Center (AWS SSO)
# IAM Identity Centerは既にOrganizationsと統合されているため、データソースで参照
data "aws_ssoadmin_instances" "main" {}

# adminグループの作成
resource "aws_identitystore_group" "admin" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  display_name      = "admin"
  description       = "Administrator group - Full permissions granted"
}

# pioneerユーザの作成
resource "aws_identitystore_user" "pioneer" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  user_name         = "pioneer"
  display_name      = "Pioneer User"

  name {
    given_name  = "Pioneer"
    family_name = "User"
  }

  emails {
    value   = var.pioneer_email
    type    = "work"
    primary = true
  }
}

# pioneerユーザをadminグループに追加
resource "aws_identitystore_group_membership" "pioneer_admin" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
  group_id          = aws_identitystore_group.admin.group_id
  member_id         = aws_identitystore_user.pioneer.user_id
}

# AdministratorAccessの許可セット作成
resource "aws_ssoadmin_permission_set" "administrator_access" {
  instance_arn     = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  name             = "AdministratorAccess"
  description      = "Administrator access - Full access to all AWS services"
  session_duration = "PT12H"
}

# AdministratorAccessポリシーをアタッチ
resource "aws_ssoadmin_managed_policy_attachment" "administrator_access" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# adminグループにAdministratorAccessを割り当て(マスターアカウント)
resource "aws_ssoadmin_account_assignment" "admin_assignment_master" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn
  principal_id       = aws_identitystore_group.admin.group_id
  principal_type     = "GROUP"
  target_id          = aws_organizations_organization.main.master_account_id
  target_type        = "AWS_ACCOUNT"
}

# adminグループにAdministratorAccessを割り当て(prodアカウント)
resource "aws_ssoadmin_account_assignment" "admin_assignment_prod" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn
  principal_id       = aws_identitystore_group.admin.group_id
  principal_type     = "GROUP"
  target_id          = aws_organizations_account.prod.id
  target_type        = "AWS_ACCOUNT"
}

# adminグループにAdministratorAccessを割り当て(stgアカウント)
resource "aws_ssoadmin_account_assignment" "admin_assignment_stg" {
  instance_arn       = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.administrator_access.arn
  principal_id       = aws_identitystore_group.admin.group_id
  principal_type     = "GROUP"
  target_id          = aws_organizations_account.stg.id
  target_type        = "AWS_ACCOUNT"
}

# Identity Centerインスタンスの情報を出力
output "identity_center_instance_arn" {
  description = "IAM Identity Center instance ARN"
  value       = try(tolist(data.aws_ssoadmin_instances.main.arns)[0], null)
}

output "identity_center_identity_store_id" {
  description = "IAM Identity Center identity store ID"
  value       = try(tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0], null)
}

output "admin_group_id" {
  description = "Admin group ID"
  value       = aws_identitystore_group.admin.group_id
}

output "pioneer_user_id" {
  description = "Pioneer user ID"
  value       = aws_identitystore_user.pioneer.user_id
}
