resource "aws_ssm_parameter" "service_registration_url" {
  for_each = var.urls_to_register

  name  = "/notifycal/${var.environment}/${each.key}/url"
  type  = "String"
  value = each.value
}
