# ---------------------------------------------------------------------------
# 問い合わせ API: API Gateway HTTP API + Lambda。
# サイト（pages.master.makedara.work）の問い合わせフォームから POST /contact を受け、
# Cloudflare Turnstile 検証後に SES で運営宛通知メールを送信する。
#
# Lambda は lambda/contact/index.mjs（依存追加なしの自己完結 ESM。lambda/ses-forward と同方針）。
# SES 送信先 contact@ は既存 SES 受信転送に乗るため、SES 側の新規設定は不要。
# ---------------------------------------------------------------------------

# --- Lambda パッケージ ------------------------------------------------------

data "archive_file" "contact" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/contact"
  output_path = "${path.module}/.terraform/tmp/contact.zip"
}

resource "aws_cloudwatch_log_group" "contact" {
  name              = "/aws/lambda/master-contact"
  retention_in_days = 14
}

# --- Turnstile シークレット（SSM SecureString・実値は apply 後に手動投入）------

resource "aws_ssm_parameter" "turnstile_secret" {
  name        = "/master/turnstile/secret-key"
  description = "Cloudflare Turnstile secret key for pages.master.makedara.work. Set manually via AWS CLI."
  type        = "SecureString"
  value       = "PLACEHOLDER_REPLACE_MANUALLY"

  lifecycle {
    ignore_changes = [value]
  }
}

# --- Lambda 実行ロール（最小権限）------------------------------------------
# 信頼ポリシー data.aws_iam_policy_document.lambda_assume_role は ses-inbound.tf で定義済みを流用する。

resource "aws_iam_role" "contact" {
  name               = "master-contact-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "contact_basic_execution" {
  role       = aws_iam_role.contact.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "contact_inline" {
  # SES 送信（From を noreply@ に固定）。ses-inbound.tf の SESForwardSend と同じ作法。
  statement {
    sid       = "SESSendNotification"
    effect    = "Allow"
    actions   = ["ses:SendEmail"]
    resources = ["arn:aws:ses:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:identity/*"]

    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"
      values   = [local.contact_mail_from]
    }
  }

  # Turnstile シークレット（SecureString）の取得。
  statement {
    sid       = "SSMGetTurnstileSecret"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = [aws_ssm_parameter.turnstile_secret.arn]
  }

  # SecureString 復号（SSM の AWS 管理キー経由のみに限定）。
  statement {
    sid       = "KMSDecryptViaSSM"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "contact_inline" {
  name   = "master-contact-inline"
  role   = aws_iam_role.contact.id
  policy = data.aws_iam_policy_document.contact_inline.json
}

# --- Lambda 関数 ------------------------------------------------------------

resource "aws_lambda_function" "contact" {
  function_name = "master-contact"
  role          = aws_iam_role.contact.arn
  runtime       = "nodejs22.x"
  handler       = "index.handler"
  architectures = ["arm64"]

  filename         = data.archive_file.contact.output_path
  source_code_hash = data.archive_file.contact.output_base64sha256

  timeout     = 15
  memory_size = 256

  environment {
    variables = {
      CONTACT_MAIL_FROM         = local.contact_mail_from
      CONTACT_MAIL_TO           = local.contact_mail_to
      CONTACT_MAIL_SUBJECT      = local.contact_mail_subject
      TURNSTILE_SECRET_SSM_NAME = aws_ssm_parameter.turnstile_secret.name
      ALLOW_ORIGIN              = "https://${local.pages_domain}"
    }
  }

  depends_on = [aws_cloudwatch_log_group.contact]
}

# --- API Gateway HTTP API ---------------------------------------------------

resource "aws_apigatewayv2_api" "contact" {
  name          = "master-contact"
  protocol_type = "HTTP"
  description   = "Contact form API for ${local.pages_domain}"

  # 問い合わせフォーム（サイト本体オリジン）からのブラウザアクセスのみ許可する。
  cors_configuration {
    allow_origins = ["https://${local.pages_domain}"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type"]
    max_age       = 3600
  }
}

resource "aws_apigatewayv2_integration" "contact" {
  api_id                 = aws_apigatewayv2_api.contact.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.contact.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "contact" {
  api_id    = aws_apigatewayv2_api.contact.id
  route_key = "POST /contact"
  target    = "integrations/${aws_apigatewayv2_integration.contact.id}"
}

resource "aws_cloudwatch_log_group" "contact_apigw" {
  name              = "/aws/apigateway/master-contact"
  retention_in_days = 14
}

resource "aws_apigatewayv2_stage" "contact" {
  api_id      = aws_apigatewayv2_api.contact.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.contact_apigw.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
    })
  }
}

resource "aws_lambda_permission" "contact_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contact.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.contact.execution_arn}/*/*"
}
