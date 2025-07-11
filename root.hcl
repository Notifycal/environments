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
      Stack         = local.stack_name
      Stack-Version = local.stack_version
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

  pre_plan_apply_destroy_hook_command = <<EOF
  if [[ "$${LOCAL_DEV}" == "true" ]]; then
    hook_script=ci/pre-plan-apply.local.sh
  else
    hook_script=ci/pre-plan-apply.sh
  fi
  
  if [[ "$${TG_SKIP_HOOKS}" == "true" || "$${TG_SKIP_PRE_PLAN_HOOK}" == "true" ]]; then
    echo "The $${hook_script} hook has been disabled through an environment variable."
  else
    if [[ -f $${hook_script} ]]; then
      echo "$${hook_script} file found!"
      $${hook_script} ${local.stack_name} ${local.stack_version} ${local.merged_inputs.environment} ${get_terragrunt_dir()}
    else
      echo "No $${hook_script} file found, skipping."
    fi
  fi
  EOF

  post_apply_hook_command = <<EOF
  if [[ "$${LOCAL_DEV}" == "true" ]]; then
    hook_script=ci/post-apply.local.sh
  else
    hook_script=ci/post-apply.sh
  fi

  if [[ "$${TG_SKIP_HOOKS}" == "true" || "$${TG_SKIP_POST_APPLY_HOOK}" == "true" ]]; then
    echo "The $${hook_script} hook has been disabled through an environment variable."
  else
    if [[ -f $${hook_script} ]]; then
      echo "$${hook_script} file found!"
      $${hook_script} ${local.stack_name} ${local.stack_version} ${local.merged_inputs.environment} ${get_terragrunt_dir()}
    else
      echo "No $${hook_script} file found, skipping."
    fi
  fi
  EOF

  install_tofu_hook = <<EOF
    if [[ $CI != "true" ]]; then
      tenv tofu install 1>&2
    else
      echo "Skipping 'install_tofu_version' hook because CI == true." 1>&2
    fi
  EOF

  # <org>/<repo_name> or null
  git_source_repository = (
    try(one(regex(
      # This regex covers the following formats of module URLs. Only for github.
      # - git@github.com:org/repo.git
      # - ssh://git@github.com/org/repo.git
      # - https://github.com/org/repo.git
      "^(?:git::)?(?:ssh://git@github\\.com/|git@github\\.com:|https://github\\.com/)([^/]+/[^/.]+)",
      local.stack_config.base_source_url
    )), null)
  )

  # Doing this because Terragrunt doesn't do short-circuit for conditional run_cmd :(
  # https://github.com/gruntwork-io/terragrunt/issues/1448
  # https://github.com/gruntwork-io/terragrunt/issues/2361
  # https://github.com/gruntwork-io/terragrunt/issues/1427
  get_latest_release_command = (local.git_source_repository != null ?
    "gh release list --repo ${local.git_source_repository} --json name,isLatest --jq '.[] | select(.isLatest)|.name'" :
    "echo"
  )

  # run_cmd will always run, regardless of condition. Uses the stack_version from env.json if isn't "main" or ""
  resolved_stack_version = (contains(["", "latest"], local.stack_version) ?
    trimspace(run_cmd("--terragrunt-quiet", "bash", "-c", local.get_latest_release_command)) :
    local.stack_version
  )
}

terraform {
  before_hook "install_tofu_version" {
    commands = ["init", "state", "import", "refresh", "output", "taint", "untaint", "plan", "apply"]
    # Redirecting the output to stderr to avoid the output being captured by Terragrunt. Otherwise, `terragrunt output -json` won't return valid JSON.
    execute     = [get_env("SHELL", "/bin/bash"), "-ce", local.install_tofu_hook]
    working_dir = "${get_terragrunt_dir()}"
  }

  after_hook "post_apply_stack" {
    commands    = ["apply"]
    execute     = [get_env("SHELL", "/bin/bash"), "-ce", local.post_apply_hook_command]
    working_dir = "${get_working_dir()}/.."
  }

  before_hook "pre_plan_apply_destroy_stack" {
    commands    = ["plan", "apply", "destroy"]
    execute     = [get_env("SHELL", "/bin/bash"), "-ce", local.pre_plan_apply_destroy_hook_command]
    working_dir = "${get_working_dir()}/.."
  }

  extra_arguments "localstack_auth" {
    commands  = ["init", "plan", "apply"]
    arguments = []
    env_vars = local.is_local_env ? {
      AWS_ENDPOINT_URL = "http://localhost:4566"
    } : {}
  }

  source = local.resolved_stack_version == "" ? local.stack_config.base_source_url : "${local.stack_config.base_source_url}?ref=${local.resolved_stack_version}"
}

remote_state = local.remote_state
inputs = merge(
  local.merged_inputs,
  {
    _tags        = local.stack_tags,
    _aws_region  = local.merged_inputs.aws_region
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
  disable     = !can(local.stack_config.required_providers.aws)
  if_disabled = "remove_terragrunt"
  if_exists   = "overwrite"

  path     = "_tg.provider.aws.tf"
  contents = file("${get_repo_root()}/providers/aws.tf")
}

generate "provider_cloudflare" {
  disable     = !can(local.stack_config.required_providers.cloudflare)
  if_disabled = "remove_terragrunt"
  if_exists   = "overwrite"

  path     = "_tg.provider.cloudflare.tf"
  contents = file("${get_repo_root()}/providers/cloudflare.tf")
}

generate "provider_stripe" {
  disable     = !can(local.stack_config.required_providers.stripe)
  if_disabled = "remove_terragrunt"
  if_exists   = "overwrite"

  path     = "_tg.provider.stripe.tf"
  contents = file("${get_repo_root()}/providers/stripe.tf")
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

generate "ssm_param_registration" {
  disable     = try(!local.stack_config.register, true)
  if_disabled = "remove_terragrunt" // What to do if a file already exists at path and disable is set to true
  if_exists   = "overwrite"

  path              = "_tg.register_service.tf"
  disable_signature = true

  # This relies on some convention. TODO: Write docs:
  # 1. We expect the stack to expose a local: _service_registration_url
  contents = <<EOF
resource "aws_ssm_parameter" "service_registration" {
  name        = "/notifycal/${local.merged_inputs.environment}/${local.stack_name}/url"
  type        = "String"
  value       = local._service_registration_url
}
EOF
}

dependency "localstack" {
  enabled      = local.is_local_env && local.stack_name != "localstack"
  config_path  = "${get_terragrunt_dir()}/../localstack"
  skip_outputs = true
}
