data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# master.makedara.work の Route53 ホストゾーン（手動作成済み。Zone ID を tfvars で投入）。
data "aws_route53_zone" "makedara" {
  zone_id = var.master_makedara_zone_id
}
