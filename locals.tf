locals {
  makedara_domain    = "master.makedara.work"
  contact_mail_to    = "contact@${local.makedara_domain}" # 受信 & Gmail 返信の名乗り
  contact_mail_from  = "noreply@${local.makedara_domain}" # 転送 Lambda の書換後 From
  ses_inbound_prefix = "inbound/"

  # 受信バケット名の UUID を一元管理（グローバル一意にするため固定 UUID を付与）。
  ses_inbound_bucket_uuid = "03da39ab-5aab-44cd-afef-43666e52e62d"
  ses_inbound_bucket_name = "master-ses-inbound-${local.ses_inbound_bucket_uuid}"

  # Abenotech 事業紹介サイト（master.makedara.work）。
  pages_domain = local.makedara_domain

  # apex ドメイン。master.makedara.work とは別ホストゾーンで管理する。
  apex_domain = "makedara.work"

  # サイトを配信するホスト名（CloudFront alias / ACM 証明書 / CORS 許可オリジンの対象）。
  pages_domains = [local.pages_domain, local.apex_domain]

  # ACM DNS 検証レコードの登録先ゾーン（ドメインごとに所属ゾーンが異なる）。
  pages_cert_zone_ids = {
    (local.pages_domain) = data.aws_route53_zone.makedara.zone_id
    (local.apex_domain)  = data.aws_route53_zone.makedara_apex.zone_id
  }

  # 配信バケット名の UUID を一元管理（グローバル一意にするため固定 UUID を付与）。
  pages_bucket_uuid = "fd50acc4-0697-427a-a30f-3a03e12a4bb6"
  pages_bucket_name = "pages-${local.pages_bucket_uuid}"

  # 問い合わせ通知メールの件名。
  contact_mail_subject = "【Abenotech】お問い合わせ"

  # apex ゾーンから NS 委譲するサブドメイン群（キーはラベルのみ）。
  # 委譲先ホストゾーンは各メンバーアカウント（organizations.tf 参照）側にあり、
  # master アカウントの credential では data.aws_route53_zone で参照できないため NS 値を直接記述する。
  # 委譲先ゾーンを作り直すと NS が変わり委譲が切れるので、その際はここの値も追従させること。
  # master.makedara.work は aws_route53_record.master_delegation で別管理。
  subdomain_delegations = {
    "kidsword" = [
      "ns-74.awsdns-09.com.",
      "ns-973.awsdns-57.net.",
      "ns-1087.awsdns-07.org.",
      "ns-1579.awsdns-05.co.uk.",
    ]
    "kidsword-stg" = [
      "ns-374.awsdns-46.com.",
      "ns-582.awsdns-08.net.",
      "ns-1235.awsdns-26.org.",
      "ns-1636.awsdns-12.co.uk.",
    ]
    "multibook-stg" = [
      "ns-400.awsdns-50.com.",
      "ns-762.awsdns-31.net.",
      "ns-1517.awsdns-61.org.",
      "ns-1616.awsdns-10.co.uk.",
    ]
    "static" = [
      "ns-209.awsdns-26.com.",
      "ns-995.awsdns-60.net.",
      "ns-1243.awsdns-27.org.",
      "ns-1894.awsdns-44.co.uk.",
    ]
    "static-stg" = [
      "ns-95.awsdns-11.com.",
      "ns-647.awsdns-16.net.",
      "ns-1113.awsdns-11.org.",
      "ns-1810.awsdns-34.co.uk.",
    ]
  }
}
