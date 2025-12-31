# AWS Organizations
resource "aws_organizations_organization" "main" {
  aws_service_access_principals = [
    "sso.amazonaws.com",
  ]

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
  ]

  feature_set = "ALL"
}

# Static Production Account
resource "aws_organizations_account" "static_prod" {
  name  = "static-prod"
  email = var.static_prod_account_email

  depends_on = [aws_organizations_organization.main]
}

# Static Staging Account
resource "aws_organizations_account" "static_stg" {
  name  = "static-stg"
  email = var.static_stg_account_email

  depends_on = [aws_organizations_organization.main]
}
