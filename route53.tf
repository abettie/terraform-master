# ---------------------------------------------------------------------------
# 送信到達性向上のための DNS レコード（SPF / DMARC）。
# DKIM CNAME・MX は ses.tf / ses-inbound.tf 側で管理する。
# ---------------------------------------------------------------------------

# SPF: SES を正規の送信元として宣言する（apex に TXT）。
resource "aws_route53_record" "spf" {
  zone_id = data.aws_route53_zone.makedara.zone_id
  name    = local.makedara_domain
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:amazonses.com ~all"]
}

# DMARC: 監視モード（p=none）。集約レポートを転送先へ送る。
resource "aws_route53_record" "dmarc" {
  zone_id = data.aws_route53_zone.makedara.zone_id
  name    = "_dmarc.${local.makedara_domain}"
  type    = "TXT"
  ttl     = 300
  records = ["v=DMARC1; p=none; rua=mailto:${var.contact_forward_to}"]
}
