locals {
  stack_name  = basename(path_relative_to_include())
  environment = basename(dirname(path_relative_to_include()))
}

dependency "url_registry" {
  config_path = "${get_terragrunt_dir()}/../url_registry"
  skip_outputs = true
}

inputs = {
  base_domain = "notifycal.com"
  # Production does not require any prefixes in the domain/URLs
  domain_prefix = local.environment == "prod" ? "" : local.environment
}
