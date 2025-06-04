resource "aws_ssm_parameter" "stripe_admin_api_key" {
  name  = "/notifycal/${var.environment}/providers/stripe/admin_api_key"
  type  = "SecureString"
  value = var.stripe_admin_api_key

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ssm_parameter" "stripe_operating_api_key" {
  name  = "/notifycal/${var.environment}/providers/stripe/operating_api_key"
  type  = "SecureString"
  value = var.stripe_operating_api_key

  lifecycle {
    prevent_destroy = true
  }
}
