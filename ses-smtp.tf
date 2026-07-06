# =============================================================================
# SES SMTP 送信用の認証情報（Gmail の「他のアドレスから送信」返信用）
# =============================================================================
# 目的: Gmail の「他のアドレスから送信（Send mail as）」の送信 SMTP サーバとして SES を使い、
#       問い合わせ（contact@master.makedara.work）への返信 From を contact@ にできるようにする。
#       個人 Gmail アドレスを相手に露出させないための構成。
#
# 仕組み: SES の SMTP インターフェースは IAM 認証情報を SMTP ユーザ名／パスワードに変換して使う。
#         SMTP 経由の送信は内部的に `ses:SendRawEmail` として評価される。SMTP パスワードは
#         access key の secret を SigV4 で導出した専用文字列で、`ses_smtp_password_v4` 属性から取得する。
#
# 注意: 任意の宛先（問い合わせ者）へ返信するには SES プロダクションアクセス（サンドボックス解除）が必要。

resource "aws_iam_user" "ses_smtp" {
  name = "master-ses-smtp"
}

resource "aws_iam_access_key" "ses_smtp" {
  user = aws_iam_user.ses_smtp.name
}

data "aws_iam_policy_document" "ses_smtp_send" {
  statement {
    sid     = "SESSmtpSendRaw"
    effect  = "Allow"
    actions = ["ses:SendRawEmail"]
    # サンドボックスでは受信者（To）identity の認可も評価されるため、リージョン内の全 identity を
    # 対象にしつつ、下の ses:FromAddress 条件で送信元を contact@ に固定する（554 対策）。
    # ドメイン identity のみに絞ると、検証済み受信者宛でも受信者 identity の認可で弾かれ 554 になる。
    resources = ["arn:aws:ses:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:identity/*"]

    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"
      # From を contact@ に固定する。Gmail の Send mail as 認証時に From が異なるとブロックされ得る。
      values = [local.contact_mail_to]
    }
  }
}

resource "aws_iam_user_policy" "ses_smtp_send" {
  name   = "master-ses-smtp-send"
  user   = aws_iam_user.ses_smtp.name
  policy = data.aws_iam_policy_document.ses_smtp_send.json
}
