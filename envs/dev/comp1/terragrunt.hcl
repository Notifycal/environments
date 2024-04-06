include "root" {
  path = find_in_parent_folders()
}
include "stack" {
  path = "${get_repo_root()}/stacks/${basename(get_terragrunt_dir())}/terragrunt.hcl"
}
inputs = {
  comp_specific = "foo"
}