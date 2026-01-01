# IAM Role for Switch Role from Main Account to Static-Prod Account
resource "aws_iam_role" "switch_role_static_prod" {
  provider = aws.static_prod
  name     = "SwitchRoleFromMain"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${aws_organizations_organization.main.master_account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "SwitchRoleFromMain"
  }
}

# Attach AdministratorAccess policy to static-prod switch role
resource "aws_iam_role_policy_attachment" "switch_role_static_prod_admin" {
  provider   = aws.static_prod
  role       = aws_iam_role.switch_role_static_prod.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# IAM Role for Switch Role from Main Account to Static-Stg Account
resource "aws_iam_role" "switch_role_static_stg" {
  provider = aws.static_stg
  name     = "SwitchRoleFromMain"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${aws_organizations_organization.main.master_account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "SwitchRoleFromMain"
  }
}

# Attach AdministratorAccess policy to static-stg switch role
resource "aws_iam_role_policy_attachment" "switch_role_static_stg_admin" {
  provider   = aws.static_stg
  role       = aws_iam_role.switch_role_static_stg.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Output the role ARNs for easy reference
output "switch_role_static_prod_arn" {
  description = "ARN of the switch role for static-prod account"
  value       = aws_iam_role.switch_role_static_prod.arn
}

output "switch_role_static_stg_arn" {
  description = "ARN of the switch role for static-stg account"
  value       = aws_iam_role.switch_role_static_stg.arn
}
