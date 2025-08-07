output "frontend_url" {
  value = {
    domain_prefix = var.urls_to_register.frontend.domain_prefix
    base_domain = var.base_domain
  }
}

output "static_landing_url" {
  value = {
    domain_prefix = var.urls_to_register.static-landing.domain_prefix
    base_domain = var.base_domain
  }
}
