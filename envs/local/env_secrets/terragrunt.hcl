include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}
include "stack" {
  path = "${get_repo_root()}/stacks/${basename(get_terragrunt_dir())}/terragrunt.hcl"
}

inputs = {
}
