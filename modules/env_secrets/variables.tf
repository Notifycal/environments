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
