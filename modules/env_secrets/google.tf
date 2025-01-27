resource "aws_ssm_parameter" "google_oauth_client_id" {
  name  = "/notifycal/${var.environment}/providers/google/oauth/client-id"
  type  = "String"
  value = var.google_oauth_client_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ssm_parameter" "google_oauth_client_secret" {
  name  = "/notifycal/${var.environment}/providers/google/oauth/client-secret"
  type  = "SecureString"
  value = var.google_oauth_client_secret

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ssm_parameter" "redirect_url" {
  name  = "/notifycal/${var.environment}/providers/google/oauth/redirect-url"
  type  = "String"
  value = var.google_oauth_redirect_url

  lifecycle {
    prevent_destroy = true
  }
}
