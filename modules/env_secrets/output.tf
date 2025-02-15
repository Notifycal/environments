output "google_oauth_client_id" {
  value = var.google_oauth_client_id
}

output "google_oauth_client_secret" {
  value     = var.google_oauth_client_secret
  sensitive = true
}

output "google_oauth_redirect_url" {
  value = var.google_oauth_redirect_url
}

output "vonage_application_id" {
  value = var.vonage_application_id
}

output "vonage_auth_private_key" {
  value = var.vonage_auth_private_key
  sensitive = true
}
