locals {
  environment = basename(dirname(path_relative_to_include()))
  base_domain = "notifycal.com"

  # Production does not require any env-scoped prefixes in the domain/URLs. But the other environments
  # do, due to a Cloudflare subdomain limitation for free accounts
  frontend_domain_prefix       = local.environment == "prod" ? "private" : "private${local.environment}"
  static_landing_domain_prefix = local.environment == "prod" ? "" : local.environment
}

dependency "backend" {
  config_path = "${get_terragrunt_dir()}/../backend"

  mock_outputs = {
    api_url = "https://mock-api-url.com"
  }

  mock_outputs_allowed_terraform_commands = ["init", "providers", "validate", "plan", "destroy"]
}

inputs = {
  base_domain = local.base_domain
  urls_to_register = {
    backend = dependency.backend.outputs.api_url
    frontend = {
      domain_prefix = local.frontend_domain_prefix
    }
    static-landing = {
      domain_prefix = local.static_landing_domain_prefix
    }
  }
}
