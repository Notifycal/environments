locals {
  environment = basename(dirname(path_relative_to_include()))
  base_domain = "notifycal.com"

  frontend_domain_prefix       = local.environment == "prod" ? "private" : "private${local.environment}"
  static_landing_domain_prefix = local.environment == "prod" ? "" : local.environment
}

dependency "backend" {
  config_path = "${get_terragrunt_dir()}/../backend"

  mock_outputs = {
    api_url = "https://mock-api-url.com"
  }

  mock_outputs_allowed_terraform_commands = ["init", "providers", "validate", "plan"]
}

inputs = {
  urls_to_register = {
    backend        = dependency.backend.outputs.api_url
    frontend       = "https://${local.frontend_domain_prefix}.${local.base_domain}"
    static-landing = "https://${local.static_landing_domain_prefix}.${local.base_domain}"
  }
}
