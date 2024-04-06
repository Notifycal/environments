locals {
  global_vars = read_terragrunt_config(find_in_parent_folders("global.hcl"))
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  merged_inputs = merge(
    local.global_vars.locals,
    local.environment_vars.locals
  )
  stack_name = basename(path_relative_to_include())
  stack_path = "${get_repo_root()}/stacks/${local.stack_name}"
  stack_version = local.merged_inputs.stack_versions[local.stack_name]

  _is_ephemeral_deploy = get_env("EPHEMERAL_DEPLOY", "false")
  environment_tags = {
      Project = local.merged_inputs.project_name
      Region = local.merged_inputs.aws_region
      Environment = local.merged_inputs.environment
      Managed-By = "Terragrunt"
      Ephemeral-Deploy = local._is_ephemeral_deploy
  }
  stack_tags = merge(
    local.environment_tags, 
    { 
      Stack = local.stack_name
    }
  )
  is_local_env = local.merged_inputs.environment == "local"

  remote_state = {
    backend = !local.is_local_env ? "s3" : "local"
    config = [{
      bucket = "tofu-state-${local.merged_inputs.project_name}-${local.merged_inputs.environment}"
      key = "${local.stack_name}/terraform.tfstate"
      region = local.merged_inputs.aws_region
      encrypt = true
      dynamodb_table = "tofu-lock-${local.merged_inputs.project_name}-${local.merged_inputs.environment}"
      s3_bucket_tags = local.environment_tags
      dynamodb_table_tags = local.environment_tags
    }, {}][!local.is_local_env ? 0 : 1 ]
    generate = {
      path = "_tg.backend.tf"
      if_exists = "overwrite"
    }
  }
  stack_config = jsondecode(file("${local.stack_path}/source.json"))
  stack_providers_filename = "_tg.provider.versions.tf"
}

terraform {
  before_hook "install_tg_and_tofu_versions" {
    commands    = ["init", "state", "import", "refresh", "output", "taint", "untaint", "plan", "apply"]
    execute     = [ get_env("SHELL", "/bin/bash"), "-ce", "tenv tg install && tenv tofu install"]
    working_dir = "${get_terragrunt_dir()}"
  }
  source = local.stack_version == "" ? local.stack_config.base_source_url : "${local.stack_config.base_source_url}?ref=${local.stack_version}"
}

remote_state = local.remote_state
inputs = merge(local.merged_inputs, { _tags = local.stack_tags })

generate "provider_versions" {
  path = "../${local.stack_providers_filename}"
  if_exists = "overwrite"
  contents = templatefile("${get_repo_root()}/providers/required_providers.tftpl", { required_providers: local.stack_config.required_providers})
}

generate "stack_provider_versions" {
  path = local.stack_providers_filename
  if_exists = "overwrite"
  contents = <<-EOF
  module "stack_provider_versions" {
    source = "../"
  }
  EOF
}

generate "provider_aws" {
  disable = !can(local.stack_config.required_providers.aws)
  path = "_tg.provider.aws.tf"
  if_exists = "overwrite"
  contents = file("${get_repo_root()}/providers/aws.tf")
}

generate "tofu_version" {
  path = ".opentofu-version"
  if_exists = "overwrite"
  contents = file("${get_repo_root()}/.opentofu-version")
}

generate "tg_version" {
  path = ".terragrunt-version"
  if_exists = "overwrite"
  contents = file("${get_repo_root()}/.terragrunt-version")
}

generate "vars" {
  path = "_tg.variables.tf"
  if_exists = "overwrite"
  contents = file("${get_repo_root()}/stacks/variables.tf")
}

dependency "localstack" {
  enabled = local.is_local_env && local.stack_name != "localstack"
  config_path = "${get_terragrunt_dir()}/../localstack"
  skip_outputs = true
}