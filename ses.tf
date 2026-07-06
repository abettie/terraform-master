# ---------------------------------------------------------------------------
# SES ドメイン identity + Easy DKIM
# master.makedara.work をドメイン identity として登録し、Easy DKIM の CNAME 3 件を
# Route53 に登録して検証する（_amazonses TXT 検証は不要）。
# ---------------------------------------------------------------------------

resource "aws_sesv2_email_identity" "makedara" {
  email_identity = local.makedara_domain

  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }
}

# SES が発行する DKIM 用 CNAME レコード（3 件）を Route53 に登録する。
# Easy DKIM は常に 3 トークンを生成するため count = 3 で固定する。
# （for_each はキーがトークン値=apply 時まで unknown のため使用不可）
# DKIM 検証が完了すると SES identity の dkim_status が SUCCESS になる。
resource "aws_route53_record" "ses_dkim" {
  count = 3

  zone_id = data.aws_route53_zone.makedara.zone_id
  name    = "${aws_sesv2_email_identity.makedara.dkim_signing_attributes[0].tokens[count.index]}._domainkey.${local.makedara_domain}"
  type    = "CNAME"
  ttl     = 300
  records = ["${aws_sesv2_email_identity.makedara.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]
}
