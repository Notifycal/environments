variable "environment" {}

variable "jwt_config" {
  type = object({
    access = object({
      algorithm  = optional(string, "ES256")
      audience   = optional(string, "notifycal.com")
      expiration = optional(string, "5m")
      issuer     = optional(string, "notifycal.com")
    })
    refresh = object({
      algorithm  = optional(string, "ES256")
      audience   = optional(string, "notifycal.com")
      expiration = optional(string, "7d")
      issuer     = optional(string, "notifycal.com")
    })
  })
  default = {
    access  = {}
    refresh = {}
  }

  validation {
    condition = (
      substr(var.jwt_config.access.algorithm, 0, 2) == "ES" &&
      substr(var.jwt_config.refresh.algorithm, 0, 2) == "ES" &&
      contains(["224", "256", "384", "521"], substr(var.jwt_config.access.algorithm, 2, -1)) &&
      contains(["224", "256", "384", "521"], substr(var.jwt_config.refresh.algorithm, 2, -1))
    )
    error_message = "The algorithm for both access and refresh tokens must be: ES224, ES256, ES384 or ES521"
  }
}

variable "google_oauth_client_id" {
  type = string
}

variable "google_oauth_client_secret" {
  type      = string
  sensitive = true
}

variable "vonage_api_key" {
  type = string
}

variable "vonage_application_id" {
  type = string
}

variable "vonage_webhook_jwt_signing_secret" {
  type      = string
  sensitive = true
}
variable "vonage_auth_private_key" {
  type      = string
  sensitive = true
}

variable "mailgun_api_key" {
  type = string
}

variable "stripe_admin_api_key" {
  description = "Stripe admin API key"
  type        = string
  sensitive   = true
}

variable "stripe_operating_api_key" {
  description = "Stripe operating API key"
  type        = string
  sensitive   = true
}
variable "stripe_admin_webhook_url" {
  description = "Endpoint URL for Stripe to send admin-level updates such us new customer, disputes open, etc.. Typically, it will be the Stripe Slack App. It requires a manual step: check out https://notifycal.slack.com/marketplace/A0F81FNVC-stripe"
  type        = string
  sensitive   = true
  default     = null
}