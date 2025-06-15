locals {
  stack_name  = basename(path_relative_to_include())
  environment = basename(dirname(path_relative_to_include()))
}

dependency "backend" {
  config_path = "${get_terragrunt_dir()}/../backend"

  # There are no outputs from frontend that backend would need to use.
  skip_outputs = true
}

inputs = {
  base_domain = "notifycal.com"
  # Production does not require any prefixes in the domain/URLs
  domain_prefix = local.environment == "prod" ? "private" : "private${local.environment}"
}
