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
