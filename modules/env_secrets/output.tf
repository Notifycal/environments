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
  value = var.vonage_auth_private_key
  sensitive = true
}

output "vonage_auth_public_key_ssm_parameter_name" {
  value = aws_ssm_parameter.vonage_public_key.name
}

output "vonage_webhook_jwt_signing_secret" {
  value = var.vonage_webhook_jwt_signing_secret
  sensitive = true
}

output "vonage_webhook_jwt_signing_secret_ssm_parameter_name" {
  value = aws_ssm_parameter.vonage_webhook_jwt_signing_secret.name
}

output "vonage_auth_public_key" {
  value = var.vonage_auth_public_key
  sensitive = true
}
