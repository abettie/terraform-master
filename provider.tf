provider "aws" {
  region  = "ap-northeast-1"
  profile = "terraform-master"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
    }
  }
}