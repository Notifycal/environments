variable "environment" {}

variable "google_oauth_client_id" {
  type = string
}

variable "google_oauth_client_secret" {
  type      = string
  sensitive = true
}

variable "google_oauth_redirect_url" {
  type = string
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
