locals {
  stack_name  = basename(path_relative_to_include())
  environment = basename(dirname(path_relative_to_include()))

  # Can this be a global setting for all stacks? Does it make sense?
  base_domain = "notifycal.com"
}

inputs = {
  base_domain = local.base_domain

  api_stage_name  = local.environment
  resource_suffix = local.environment

  # Production does not require any prefixes in the domain/URLs
  domain_prefix = local.environment == "prod" ? "api" : "api${local.environment}"

  # For CORS
  frontend_domain = format(
    "https://%s.%s",
    local.environment == "prod" ? "private" : "private${local.environment}",
    local.base_domain
  )
}
