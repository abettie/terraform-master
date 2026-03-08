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
