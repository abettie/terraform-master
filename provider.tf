provider "aws" {
  region = "ap-northeast-1"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}

# CloudFront 用 ACM 証明書は us-east-1 でのみ発行できるため、証明書専用の alias provider を用意する。
# 配信バケット・API Gateway・Lambda 等は既定 provider（ap-northeast-1）を使う。
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}