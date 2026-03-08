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

# Kidsword Production Account
resource "aws_organizations_account" "kidsword_prod" {
  name  = "kidsword-prod"
  email = var.kidsword_prod_account_email

  depends_on = [aws_organizations_organization.main]
}

# Kidsword Staging Account
resource "aws_organizations_account" "kidsword_stg" {
  name  = "kidsword-stg"
  email = var.kidsword_stg_account_email

  depends_on = [aws_organizations_organization.main]
}

# Multibook Production Account
resource "aws_organizations_account" "multibook_prod" {
  name  = "multibook-prod"
  email = var.multibook_prod_account_email

  depends_on = [aws_organizations_organization.main]
}

# Multibook Staging Account
resource "aws_organizations_account" "multibook_stg" {
  name  = "multibook-stg"
  email = var.multibook_stg_account_email

  depends_on = [aws_organizations_organization.main]
}
