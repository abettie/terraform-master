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

# Production Account
resource "aws_organizations_account" "prod" {
  name  = "prod"
  email = var.prod_account_email

  depends_on = [aws_organizations_organization.main]
}

# Staging Account
resource "aws_organizations_account" "stg" {
  name  = "stg"
  email = var.stg_account_email

  depends_on = [aws_organizations_organization.main]
}
