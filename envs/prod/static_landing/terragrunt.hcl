include "root" {
  path = find_in_parent_folders("root.hcl")
}
include "stack" {
  path = "${get_repo_root()}/stacks/${basename(get_terragrunt_dir())}/terragrunt.hcl"
}

inputs = {
  force_destroy_bucket = false
  enable_www_redirect  = true
  cloudflare_config = {
    private_site_auth = null
  }
}
