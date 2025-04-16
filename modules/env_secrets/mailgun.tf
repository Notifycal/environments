resource "aws_ssm_parameter" "mailgun_api_key" {
  name  = "/notifycal/${var.environment}/providers/mailgun/api-key"
  type  = "String"
  value = var.mailgun_api_key

  lifecycle {
    prevent_destroy = true
  }
}
