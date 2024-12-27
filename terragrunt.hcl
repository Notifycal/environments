locals {
  global_vars      = read_terragrunt_config(find_in_parent_folders("global.hcl"))
  environment_vars = jsondecode(file(find_in_parent_folders("env.json")))
  merged_inputs = merge(
    local.global_vars.locals,
    local.environment_vars
  )
  stack_name    = basename(path_relative_to_include())
  stack_path    = "${get_repo_root()}/stacks/${local.stack_name}"
  stack_version = local.merged_inputs.stack_versions[local.stack_name]

  _is_ephemeral_deploy = get_env("EPHEMERAL_DEPLOY", "false")
  environment_tags = {
    Project          = local.merged_inputs.project_name
    Region           = local.merged_inputs.aws_region
    Environment      = local.merged_inputs.environment
    Managed-By       = "Terragrunt"
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
      bucket              = "tofu-state-${local.merged_inputs.project_name}-${local.merged_inputs.environment}"
      key                 = "${local.stack_name}/terraform.tfstate"
      region              = local.merged_inputs.aws_region
      encrypt             = true
      dynamodb_table      = "tofu-lock-${local.merged_inputs.project_name}-${local.merged_inputs.environment}"
      s3_bucket_tags      = local.environment_tags
      dynamodb_table_tags = local.environment_tags
    }, {}][!local.is_local_env ? 0 : 1]
    generate = {
      path      = "_tg.backend.tf"
      if_exists = "overwrite"
    }
  }
  stack_config             = jsondecode(file("${local.stack_path}/source.json"))
  stack_providers_filename = "_tg.provider.versions.tf"

  pre_plan_apply_hook_command = <<EOF
  hook_script=ci/pre-plan-apply.sh
  if [[ "$${TG_SKIP_HOOKS}" == "true" || "$${TG_SKIP_PRE_PLAN_HOOK}" == "true" ]]; then
    echo "The $${hook_script} hook has been disabled through an environment variable."
  else
    if [[ -f $${hook_script} ]]; then
      echo "$${hook_script} file found!"
      $${hook_script} ${local.stack_name} ${local.stack_version} ${get_terragrunt_dir()}
    else
      echo "No $${hook_script} file found, skipping."
    fi
  fi
  EOF

  post_apply_hook_command = <<EOF
  hook_script=ci/post-apply.sh
  if [[ "$${TG_SKIP_HOOKS}" == "true" || "$${TG_SKIP_POST_APPLY_HOOK}" == "true" ]]; then
    echo "The $${hook_script} hook has been disabled through an environment variable."
  else
    if [[ -f $${hook_script} ]]; then
      echo "$${hook_script} file found!"
      $${hook_script} ${local.stack_name} ${local.stack_version} ${get_terragrunt_dir()}
    else
      echo "No $${hook_script} file found, skipping."
    fi
  fi
  EOF
}

terraform {
  after_hook "post_apply_stack" {
    commands    = ["apply"]
    execute     = [get_env("SHELL", "/bin/bash"), "-ce", local.post_apply_hook_command]
    working_dir = "${get_working_dir()}/.."
  }

  before_hook "pre_plan_apply_stack" {
    commands    = ["plan", "apply"]
    execute     = [get_env("SHELL", "/bin/bash"), "-ce", local.pre_plan_apply_hook_command]
    working_dir = "${get_working_dir()}/.."
  }

  extra_arguments "localstack_auth" {
    commands = ["init", "plan", "apply"]
    arguments = []
    env_vars = local.is_local_env ? {
      AWS_ENDPOINT_URL="http://localhost:4566"
      AWS_ACCESS_KEY_ID="foo"
      AWS_SECRET_ACCESS_KEY="bar"
    } : {}
  }

  source = local.stack_version == "" ? local.stack_config.base_source_url : "${local.stack_config.base_source_url}?ref=${local.stack_version}"
}

remote_state = local.remote_state
inputs = merge(
  local.merged_inputs,
  {
    _tags       = local.stack_tags,
    _aws_region = local.merged_inputs.aws_region
    _environment = local.merged_inputs.environment
  }
)
terraform_binary = "tofu"

generate "provider_versions" {
  path      = "../${local.stack_providers_filename}"
  if_exists = "overwrite"
  contents  = templatefile("${get_repo_root()}/providers/required_providers.tftpl", { required_providers : local.stack_config.required_providers })
}

generate "stack_provider_versions" {
  path      = local.stack_providers_filename
  if_exists = "overwrite"
  contents  = <<-EOF
  module "stack_provider_versions" {
    source = "../"
  }
  EOF
}

generate "provider_aws" {
  disable   = !can(local.stack_config.required_providers.aws)
  path      = "_tg.provider.aws.tf"
  if_exists = "overwrite"
  contents  = file("${get_repo_root()}/providers/aws.tf")
}

generate "provider_cloudflare" {
  disable   = !can(local.stack_config.required_providers.cloudflare)
  path      = "_tg.provider.cloudflare.tf"
  if_exists = "overwrite"
  contents  = file("${get_repo_root()}/providers/cloudflare.tf")
}

generate "tofu_version" {
  path              = ".opentofu-version"
  if_exists         = "overwrite"
  disable_signature = true
  contents          = file("${get_repo_root()}/.opentofu-version")
}

generate "tg_version" {
  path              = ".terragrunt-version"
  if_exists         = "overwrite"
  disable_signature = true
  contents          = file("${get_repo_root()}/.terragrunt-version")
}

generate "vars" {
  path      = "_tg.variables.tf"
  if_exists = "overwrite"
  contents  = file("${get_repo_root()}/stacks/variables.tf")
}

dependency "localstack" {
  enabled      = local.is_local_env && local.stack_name != "localstack"
  config_path  = "${get_terragrunt_dir()}/../localstack"
  skip_outputs = true
}
