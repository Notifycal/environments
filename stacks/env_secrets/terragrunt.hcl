locals {
  secrets_file_path = "${get_terragrunt_dir()}/secret.auto.tfvars"
  secrets_file_exists = run_cmd("bash", "-c", "test -f \"${local.secrets_file_path}\" && echo exists || true") == "exists"
}

inputs = {
}

exclude {
  if                   = true
  actions              = ["all"]
  exclude_dependencies = true
}

terraform {
  extra_arguments "secrets" {
    commands = ["apply", "plan", "import", "refresh", "output", "taint", "untaint", "state", "destroy"]
    arguments = local.secrets_file_exists ? [
      "-var-file=${local.secrets_file_path}"
    ] : []
  }
}
