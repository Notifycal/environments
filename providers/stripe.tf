variable "stripe_admin_api_key" {
  description = "Stripe admin API key"
  type        = string
  sensitive   = true
}

provider "stripe" {
  api_key = var.stripe_admin_api_key
}
