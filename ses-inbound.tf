# ---------------------------------------------------------------------------
# SES Inbound（メール受信）: contact@master.makedara.work 宛メールを S3 に保存し、
# 転送 Lambda で運営者の Gmail へ転送する。AWS 公式パターン「Forward Incoming Email
# to an External Destination」（受信 → S3 保存 → Lambda が S3 から生メールを読み再送信）
# に準拠する。
#
# リージョンは既定 provider（ap-northeast-1）。SES のメール受信は東京リージョンで利用可能で、
# ses.tf のドメイン identity / DKIM と data.aws_route53_zone.makedara をそのまま流用する。
# active receipt rule set はアカウント×リージョンで 1 つ（マスターアカウントは SES 未使用のため競合しない想定）。
# ---------------------------------------------------------------------------

# --- 受信メール保存用 S3 バケット -------------------------------------------

resource "aws_s3_bucket" "ses_inbound" {
  bucket = local.ses_inbound_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "ses_inbound" {
  bucket = aws_s3_bucket.ses_inbound.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "ses_inbound" {
  bucket = aws_s3_bucket.ses_inbound.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ses_inbound" {
  bucket = aws_s3_bucket.ses_inbound.id

  rule {
    apply_server_side_encryption_by_default {
      # SSE-S3（AES256）。SSE-KMS にすると SES 側に KMS 権限が別途必要になるため使わない。
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "ses_inbound" {
  bucket = aws_s3_bucket.ses_inbound.id

  # 未完了のマルチパートアップロードを 7 日後に中止（標準的な衛生設定）
  rule {
    id     = "abort-incomplete-multipart-upload"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # メールは Gmail へ転送されるため S3 は保険。365 日で失効させ保存容量を上限化する。
  rule {
    id     = "expire-inbound-emails"
    status = "Enabled"

    filter {
      prefix = local.ses_inbound_prefix
    }

    expiration {
      days = 365
    }
  }
}

# SES がこのバケットへ受信メールを書き込めるようにするバケットポリシー。
# 受信ルール作成時に SES が書き込み可否を検証するため、ルールより先に存在させる（下記 depends_on）。
data "aws_iam_policy_document" "ses_inbound_bucket" {
  statement {
    sid       = "AllowSESPuts"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.ses_inbound.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    # 自アカウントの SES からの書き込みだけを許可する（混乱した代理人問題の防止）。
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    # さらに本受信ルールセット配下のルールに限定する（ARN は文字列構築で循環参照を避ける）。
    condition {
      test     = "StringLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ses:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:receipt-rule-set/master-contact:receipt-rule/*"]
    }
  }
}

resource "aws_s3_bucket_policy" "ses_inbound" {
  bucket = aws_s3_bucket.ses_inbound.id
  policy = data.aws_iam_policy_document.ses_inbound_bucket.json
}

# --- MX レコード（このドメイン宛メールを SES 受信に向ける）-------------------

resource "aws_route53_record" "ses_mx" {
  zone_id = data.aws_route53_zone.makedara.zone_id
  name    = local.makedara_domain
  type    = "MX"
  ttl     = 300
  records = ["10 inbound-smtp.${data.aws_region.current.region}.amazonaws.com"]
}

# --- 転送 Lambda -----------------------------------------------------------

data "archive_file" "ses_forward" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/ses-forward"
  output_path = "${path.module}/.terraform/tmp/ses-forward.zip"
}

resource "aws_cloudwatch_log_group" "ses_forward" {
  name              = "/aws/lambda/master-ses-forward"
  retention_in_days = 14
}

# Lambda 実行ロールの信頼ポリシー。
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# 転送 Lambda 専用の実行ロール（最小権限）。
resource "aws_iam_role" "ses_forward" {
  name               = "master-ses-forward-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ses_forward_basic_execution" {
  role       = aws_iam_role.ses_forward.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "ses_forward_inline" {
  statement {
    sid       = "S3GetInboundEmail"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.ses_inbound.arn}/${local.ses_inbound_prefix}*"]
  }

  statement {
    sid    = "SESForwardSend"
    effect = "Allow"
    # 転送 Lambda は SendRawEmail（生 MIME）で再送信する。
    # 将来 Simple content 送信を足しても壊れないよう ses:SendEmail も許可する。
    actions = ["ses:SendEmail", "ses:SendRawEmail"]
    # サンドボックスでは宛先 identity の認可も評価されるためリージョン内の全 identity を
    # 対象にしつつ、ses:FromAddress 条件で送信元を noreply@ に固定する（554 対策）。
    resources = ["arn:aws:ses:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:identity/*"]

    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"
      values   = [local.contact_mail_from]
    }
  }
}

resource "aws_iam_role_policy" "ses_forward_inline" {
  name   = "master-ses-forward-inline"
  role   = aws_iam_role.ses_forward.id
  policy = data.aws_iam_policy_document.ses_forward_inline.json
}

resource "aws_lambda_function" "ses_forward" {
  function_name = "master-ses-forward"
  role          = aws_iam_role.ses_forward.arn
  runtime       = "nodejs22.x"
  handler       = "index.handler"
  architectures = ["arm64"]

  filename         = data.archive_file.ses_forward.output_path
  source_code_hash = data.archive_file.ses_forward.output_base64sha256

  timeout     = 30
  memory_size = 256

  environment {
    variables = {
      CONTACT_MAIL_FROM  = local.contact_mail_from
      CONTACT_FORWARD_TO = var.contact_forward_to
      SES_INBOUND_BUCKET = aws_s3_bucket.ses_inbound.bucket
      SES_INBOUND_PREFIX = local.ses_inbound_prefix
    }
  }

  depends_on = [aws_cloudwatch_log_group.ses_forward]
}

# SES 受信ルールがこの Lambda を起動できるようにする。
resource "aws_lambda_permission" "ses_forward" {
  statement_id   = "AllowSESInvoke"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.ses_forward.function_name
  principal      = "ses.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
}

# --- 受信ルールセット / ルール ---------------------------------------------
# 受信系は v1 リソース（aws_sesv2_* に受信系は無い）。

resource "aws_ses_receipt_rule_set" "this" {
  rule_set_name = "master-contact"
}

resource "aws_ses_active_receipt_rule_set" "this" {
  rule_set_name = aws_ses_receipt_rule_set.this.rule_set_name
}

resource "aws_ses_receipt_rule" "contact" {
  name          = "master-contact-rule"
  rule_set_name = aws_ses_receipt_rule_set.this.rule_set_name
  recipients    = [local.contact_mail_to]
  enabled       = true
  scan_enabled  = true
  tls_policy    = "Require"

  # アクションは順序が重要。まず S3 に保存し、その後で転送 Lambda を起動する。
  s3_action {
    bucket_name       = aws_s3_bucket.ses_inbound.bucket
    object_key_prefix = local.ses_inbound_prefix
    position          = 1
  }

  lambda_action {
    function_arn    = aws_lambda_function.ses_forward.arn
    invocation_type = "Event"
    position        = 2
  }

  # SES が S3 書き込み / Lambda 起動できる権限が先に存在しないと apply が失敗するため依存を張る。
  depends_on = [
    aws_s3_bucket_policy.ses_inbound,
    aws_lambda_permission.ses_forward,
  ]
}
