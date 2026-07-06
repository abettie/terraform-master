output "ses_smtp_endpoint" {
  description = "Gmail の Send mail as に設定する SES SMTP サーバ（ポート 587 / STARTTLS）"
  value       = "email-smtp.${data.aws_region.current.region}.amazonaws.com"
}

output "ses_smtp_username" {
  description = "SES SMTP ユーザ名（IAM アクセスキー ID）"
  value       = aws_iam_access_key.ses_smtp.id
}

output "ses_smtp_password" {
  description = "SES SMTP パスワード（access key secret を SigV4 で導出した値）"
  value       = aws_iam_access_key.ses_smtp.ses_smtp_password_v4
  sensitive   = true
}

output "ses_inbound_bucket" {
  description = "SES Inbound で受信した生メールを保存する S3 バケット名"
  value       = aws_s3_bucket.ses_inbound.bucket
}
