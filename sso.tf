# IAM Identity Center (AWS SSO)
# IAM Identity Centerは既にOrganizationsと統合されているため、データソースで参照
data "aws_ssoadmin_instances" "main" {}

# Identity Centerインスタンスの情報を出力
output "identity_center_instance_arn" {
  description = "IAM Identity Center instance ARN"
  value       = try(tolist(data.aws_ssoadmin_instances.main.arns)[0], null)
}

output "identity_center_identity_store_id" {
  description = "IAM Identity Center identity store ID"
  value       = try(tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0], null)
}
