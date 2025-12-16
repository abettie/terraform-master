terraform {
  backend "s3" {
    bucket         = "terraform-state-919172dc-8283-4326-83de-fdfadef3bb78"
    key            = "terraform.tfstate"
    region         = "ap-northeast-1"
    use_lockfile   = true
    encrypt        = true
  }
}
