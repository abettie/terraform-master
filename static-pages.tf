# ---------------------------------------------------------------------------
# Abenotech 事業紹介サイトの配信基盤: S3（非公開）+ CloudFront（OAC）+ ACM + Route53。
# https://master.makedara.work/ を HTTPS 配信する。
#
# S3 バケットは非公開のまま CloudFront の OAC（Origin Access Control）経由でのみ読み取り
# 可能にする。バケットの各種設定・ポリシー作法は ses-inbound.tf に合わせる。
# 静的コンテンツ（web/ 配下の HTML/CSS/JS）は Terraform では管理せず、
# scripts/deploy-pages.sh（aws s3 sync + CloudFront invalidation）で配置する。
# ---------------------------------------------------------------------------

# --- 配信用 S3 バケット（非公開）-------------------------------------------

resource "aws_s3_bucket" "pages" {
  bucket = local.pages_bucket_name
}

resource "aws_s3_bucket_ownership_controls" "pages" {
  bucket = aws_s3_bucket.pages.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "pages" {
  bucket = aws_s3_bucket.pages.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pages" {
  bucket = aws_s3_bucket.pages.id

  rule {
    # AWS は 2026-03 以降 新規バケットの SSE-C アップロードを自動ブロックする。
    # 実態に合わせて明示しないと毎回 plan に差分が出るため固定する。
    blocked_encryption_types = ["SSE-C"]

    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- ACM 証明書（us-east-1・DNS 検証）--------------------------------------
# CloudFront は us-east-1 の証明書のみ使用できるため aws.us_east_1 provider で発行する。

resource "aws_acm_certificate" "pages" {
  provider = aws.us_east_1

  domain_name               = local.pages_domain
  subject_alternative_names = [local.apex_domain]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# DNS 検証用レコードを Route53 に登録する。
# 対象ドメインは master.makedara.work と makedara.work で所属ホストゾーンが異なるため、
# local.pages_cert_zone_ids でドメインごとの登録先ゾーンを引く。
resource "aws_route53_record" "pages_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.pages.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      type    = dvo.resource_record_type
      record  = dvo.resource_record_value
      zone_id = local.pages_cert_zone_ids[dvo.domain_name]
    }
  }

  zone_id = each.value.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "pages" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.pages.arn
  validation_record_fqdns = [for r in aws_route53_record.pages_cert_validation : r.fqdn]
}

# --- CloudFront Function（非正規ホスト名を apex へ 301）----------------------

resource "aws_cloudfront_function" "redirect_to_apex" {
  name    = "pages-redirect-to-apex"
  runtime = "cloudfront-js-2.0"
  comment = "Redirect non-apex hosts to https://${local.apex_domain} (301)"
  publish = true

  code = templatefile("${path.module}/cloudfront-functions/redirect-to-apex.js.tftpl", {
    apex_domain = local.apex_domain
  })
}

# --- CloudFront（OAC 経由で S3 を配信）-------------------------------------

resource "aws_cloudfront_origin_access_control" "pages" {
  name                              = "pages-oac"
  description                       = "OAC for ${local.pages_domain}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "pages" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = local.pages_domain
  default_root_object = "index.html"
  aliases             = local.pages_domains
  price_class         = "PriceClass_200" # 日本を含むエッジロケーション。

  origin {
    domain_name              = aws_s3_bucket.pages.bucket_regional_domain_name
    origin_id                = "s3-pages"
    origin_access_control_id = aws_cloudfront_origin_access_control.pages.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-pages"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    # AWS マネージドキャッシュポリシー「CachingOptimized」。
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect_to_apex.arn
    }
  }

  # 直リンク（存在しないパス）でも Home を返す簡易フォールバック。
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.pages.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# --- バケットポリシー（CloudFront の該当 distribution からのみ読み取り許可）-----
# ses-inbound.tf のポリシー作法（service principal + aws:SourceArn 条件）を踏襲する。

data "aws_iam_policy_document" "pages_bucket" {
  statement {
    sid       = "AllowCloudFrontRead"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.pages.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.pages.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "pages" {
  bucket = aws_s3_bucket.pages.id
  policy = data.aws_iam_policy_document.pages_bucket.json
}

# --- Route53 ALIAS（master.makedara.work / makedara.work → CloudFront）----------------
# CloudFront の固定ホストゾーン ID は Z2FDTNDATAQYW2（AWS 共通）。
# 2 ホスト名とも同一 distribution を指し、同じコンテンツを配信する。

resource "aws_route53_record" "pages_a" {
  zone_id = data.aws_route53_zone.makedara.zone_id
  name    = local.pages_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.pages.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "pages_aaaa" {
  zone_id = data.aws_route53_zone.makedara.zone_id
  name    = local.pages_domain
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.pages.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "pages_apex_a" {
  zone_id = data.aws_route53_zone.makedara_apex.zone_id
  name    = local.apex_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.pages.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "pages_apex_aaaa" {
  zone_id = data.aws_route53_zone.makedara_apex.zone_id
  name    = local.apex_domain
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.pages.domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}
