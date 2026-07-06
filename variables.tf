variable "pioneer_email" {
  description = "Email address for the pioneer user"
  type        = string
  default     = "pioneer@example.com"
}

variable "static_prod_account_email" {
  description = "Email address for the static production account"
  type        = string
  default     = "static-prod@example.com"
}

variable "static_stg_account_email" {
  description = "Email address for the static staging account"
  type        = string
  default     = "static-stg@example.com"
}

variable "kidsword_prod_account_email" {
  description = "Email address for the kidsword production account"
  type        = string
  default     = "kidsword-prod@example.com"
}

variable "kidsword_stg_account_email" {
  description = "Email address for the kidsword staging account"
  type        = string
  default     = "kidsword-stg@example.com"
}

variable "multibook_prod_account_email" {
  description = "Email address for the multibook production account"
  type        = string
  default     = "multibook-prod@example.com"
}

variable "multibook_stg_account_email" {
  description = "Email address for the multibook staging account"
  type        = string
  default     = "multibook-stg@example.com"
}

variable "sandbox_01_account_email" {
  description = "Email address for the sandbox-01 account"
  type        = string
  default     = "sandbox-01@example.com"
}

variable "sandbox_02_account_email" {
  description = "Email address for the sandbox-02 account"
  type        = string
  default     = "sandbox-02@example.com"
}

variable "master_makedara_zone_id" {
  description = "master.makedara.work の Route53 ホストゾーンID（手動作成後に投入）"
  type        = string
  default     = ""
}

variable "contact_forward_to" {
  description = "問い合わせメールの転送先"
  type        = string
  default     = "abechinoid+master@gmail.com"
}
