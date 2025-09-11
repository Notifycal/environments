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

resource "aws_ssm_parameter" "google_tag_manager_id" {
  count = try(var.google_tag_manager_id, null) == null ? 0 : 1

  name  = "/notifycal/${var.environment}/static-landing/providers/google/tag-manager/id"
  type  = "String"
  value = var.google_tag_manager_id

  lifecycle {
    prevent_destroy = true
  }
}
