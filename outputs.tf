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

# --- Abenotech 事業紹介サイト ----------------------------------------------

output "pages_bucket_name" {
  description = "サイト配信用 S3 バケット名（deploy-pages.sh の同期先）"
  value       = aws_s3_bucket.pages.bucket
}

output "pages_cloudfront_distribution_id" {
  description = "サイト配信 CloudFront ディストリビューション ID（invalidation 用）"
  value       = aws_cloudfront_distribution.pages.id
}

output "contact_api_endpoint" {
  description = "問い合わせ API のエンドポイント（web/contact.html の __API_BASE__ に設定）"
  value       = aws_apigatewayv2_api.contact.api_endpoint
}
