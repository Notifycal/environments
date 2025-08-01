output "jwt_keys" {
  value = {
    access = {
      public_key  = tls_private_key.jwt_access_key.public_key_pem
      private_key = tls_private_key.jwt_access_key.private_key_pem
    }
    refresh = {
      public_key  = tls_private_key.jwt_refresh_key.public_key_pem
      private_key = tls_private_key.jwt_refresh_key.private_key_pem
    }
  }
  sensitive = true
}

output "jwt_config" {
  value = var.jwt_config
}

output "google_oauth_client_id" {
  value = var.google_oauth_client_id
}

output "google_oauth_client_secret" {
  value     = var.google_oauth_client_secret
  sensitive = true
}

output "vonage_api_key" {
  value = var.vonage_api_key
}

output "vonage_application_id" {
  value = var.vonage_application_id
}

output "vonage_auth_private_key_ssm_parameter_name" {
  value = aws_ssm_parameter.vonage_private_key.name
}

output "vonage_auth_private_key" {
  value     = var.vonage_auth_private_key
  sensitive = true
}

output "vonage_webhook_jwt_signing_secret" {
  value     = var.vonage_webhook_jwt_signing_secret
  sensitive = true
}

output "mailgun_api_key" {
  value = var.mailgun_api_key
}

output "stripe_admin_api_key" {
  value     = var.stripe_admin_api_key
  sensitive = true
}

output "stripe_operating_api_key" {
  value     = var.stripe_operating_api_key
  sensitive = true
}
output "stripe_admin_webhook_url" {
  value     = var.stripe_admin_webhook_url
  sensitive = true
}
