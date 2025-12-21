variable "pioneer_email" {
  description = "Email address for the pioneer user"
  type        = string
  default     = "pioneer@example.com"
}

variable "prod_account_email" {
  description = "Email address for the production account"
  type        = string
  default     = "prod@example.com"
}

variable "stg_account_email" {
  description = "Email address for the staging account"
  type        = string
  default     = "stg@example.com"
}
