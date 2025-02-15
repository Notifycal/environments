resource "aws_ssm_parameter" "vonage_application_id" {
  name  = "/notifycal/${var.environment}/providers/vonage/application-id"
  type  = "SecureString"
  value = var.vonage_application_id

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ssm_parameter" "vonage_private_key" {
  name  = "/notifycal/${var.environment}/providers/vonage/auth/jwt-private-key"
  type  = "SecureString"
  value = var.vonage_auth_private_key

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ssm_parameter" "vonage_public_key" {
  name  = "/notifycal/${var.environment}/providers/vonage/auth/jwt-public-key"
  type  = "String"
  value = var.vonage_auth_public_key

  lifecycle {
    prevent_destroy = true
  }
}
