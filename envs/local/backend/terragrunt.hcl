include "root" {
  path = find_in_parent_folders("root.hcl")
}
include "stack" {
  path = "${get_repo_root()}/stacks/${basename(get_terragrunt_dir())}/terragrunt.hcl"
}

inputs = {
  frontend_domain                   = "http://localhost:5173"
  api_gateway_custom_domain_enabled = false

  observability = null
  # This is a local environment, so we don't need to enable data protection
  enable_data_protection = false
}
