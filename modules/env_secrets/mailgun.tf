resource "aws_ssm_parameter" "mailgun_api_key" {
  name  = "/notifycal/${var.environment}/providers/mailgun/api-key"
  type  = "SecureString"
  value = var.mailgun_api_key

  lifecycle {
    prevent_destroy = true
  }
}
