#!/usr/bin/env bash
# Abenotech 事業紹介サイトの静的コンテンツ（web/ 配下）を S3 に同期し、
# CloudFront のキャッシュを無効化する。
#
# 前提:
#   - terraform apply 済み（バケット・CloudFront が存在する）
#   - AWS 認証済み（例: AWS_PROFILE=master / aws sso login --profile master）
#   - web/contact.html の __API_BASE__ / __TURNSTILE_SITE_KEY__ を実値へ置換済み
#
# 使い方:
#   AWS_PROFILE=master ./scripts/deploy-pages.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
WEB_DIR="$ROOT_DIR/web"

# バケット名・ディストリビューション ID は terraform output から取得する。
BUCKET="$(terraform -chdir="$ROOT_DIR" output -raw pages_bucket_name)"
DIST_ID="$(terraform -chdir="$ROOT_DIR" output -raw pages_cloudfront_distribution_id)"

echo "==> Sync ${WEB_DIR} -> s3://${BUCKET}"
aws s3 sync "$WEB_DIR" "s3://${BUCKET}" --delete

echo "==> Invalidate CloudFront distribution ${DIST_ID}"
aws cloudfront create-invalidation \
  --distribution-id "$DIST_ID" \
  --paths "/*" \
  --query 'Invalidation.{Id:Id,Status:Status}' \
  --output table

echo "==> Done. https://master.makedara.work/"
