# ---------------------------------------------------------------------------
# 送信到達性向上のための DNS レコード（SPF / DMARC）。
# DKIM CNAME・MX は ses.tf / ses-inbound.tf 側で管理する。
# ---------------------------------------------------------------------------

# apex の TXT レコード。Route53 は name+type ごとに 1 レコードセットへ集約されるため、
# SPF（SES の送信元宣言）と Google サイト所有権確認を同一リソースの複数値として管理する。
resource "aws_route53_record" "spf" {
  zone_id = data.aws_route53_zone.makedara.zone_id
  name    = local.makedara_domain
  type    = "TXT"
  ttl     = 300
  records = [
    "v=spf1 include:amazonses.com ~all",
    "google-site-verification=Z1YFpllTelleZU3c4kvP0SpLKXO5u-PpdcZbNowE_qw",
  ]
}

# DMARC: 監視モード（p=none）。集約レポートを転送先へ送る。
resource "aws_route53_record" "dmarc" {
  zone_id = data.aws_route53_zone.makedara.zone_id
  name    = "_dmarc.${local.makedara_domain}"
  type    = "TXT"
  ttl     = 300
  records = ["v=DMARC1; p=none; rua=mailto:${var.contact_forward_to}"]
}

# master.makedara.work は apex とは別ホストゾーンで管理しているため、apex ゾーンから NS 委譲する。
# 従来はお名前ドットコム側の DNS で委譲していたが、apex を Route53 へ移したのに伴いこちらへ移設した。
# このレコードが無いと master.makedara.work が一切引けなくなる（サイト・メールともに停止）。
resource "aws_route53_record" "master_delegation" {
  zone_id = data.aws_route53_zone.makedara_apex.zone_id
  name    = local.makedara_domain
  type    = "NS"
  ttl     = 172800
  records = data.aws_route53_zone.makedara.name_servers
}
