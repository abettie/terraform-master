provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}

# Provider for static-prod account
provider "aws" {
  alias  = "static_prod"
  region = "ap-northeast-1"

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.static_prod.id}:role/OrganizationAccountAccessRole"
  }

  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}

# Provider for static-stg account
provider "aws" {
  alias  = "static_stg"
  region = "ap-northeast-1"

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.static_stg.id}:role/OrganizationAccountAccessRole"
  }

  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}