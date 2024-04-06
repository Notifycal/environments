include "root" {
  path = find_in_parent_folders()
}
include "stack" {
  path = "${get_repo_root()}/stacks/${basename(get_terragrunt_dir())}/terragrunt.hcl"
}

inputs = {
  # How can we make this "notifycal-<stack>-<environment>" ?
  bucket_name = "notifycal-static-landing-dev"
}
