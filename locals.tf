locals {
  makedara_domain    = "master.makedara.work"
  contact_mail_to    = "contact@${local.makedara_domain}" # 受信 & Gmail 返信の名乗り
  contact_mail_from  = "noreply@${local.makedara_domain}" # 転送 Lambda の書換後 From
  ses_inbound_prefix = "inbound/"

  # 受信バケット名の UUID を一元管理（グローバル一意にするため固定 UUID を付与）。
  ses_inbound_bucket_uuid = "03da39ab-5aab-44cd-afef-43666e52e62d"
  ses_inbound_bucket_name = "master-ses-inbound-${local.ses_inbound_bucket_uuid}"
}
