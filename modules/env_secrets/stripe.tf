resource "aws_ssm_parameter" "stripe_admin_api_key" {
  name  = "/notifycal/${var.environment}/providers/stripe/admin-api-key"
  type  = "SecureString"
  value = var.stripe_admin_api_key

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ssm_parameter" "stripe_operating_api_key" {
  name  = "/notifycal/${var.environment}/providers/stripe/operating-api-key"
  type  = "SecureString"
  value = var.stripe_operating_api_key

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ssm_parameter" "stripe_admin_webhook_url" {
  count = try(var.stripe_admin_webhook_url, null) == null ? 0 : 1
  name  = "/notifycal/${var.environment}/providers/stripe/admin-webhook-url"
  type  = "SecureString"
  value = var.stripe_admin_webhook_url

  lifecycle {
    prevent_destroy = true
  }
}
