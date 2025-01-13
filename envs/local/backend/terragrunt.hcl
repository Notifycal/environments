include "root" {
  path = find_in_parent_folders()
}
include "stack" {
  path = "${get_repo_root()}/stacks/${basename(get_terragrunt_dir())}/terragrunt.hcl"
}

inputs = {
  frontend_domain                   = "http://localhost:5173"
  api_gateway_custom_domain_enabled = false
}
