resource "aws_ssm_parameter" "service_registration_url" {
  for_each = var.urls_to_register

  name = "/notifycal/${var.environment}/${each.key}/url"
  type = "String"
  value = (can(each.value.domain_prefix)
    ? "https://${each.value.domain_prefix}.${var.base_domain}"
    : tostring(each.value) # TF doesn't follow mixed types (object | string) and fails w/o `tostring`
  )
}
