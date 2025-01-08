include "root" {
  path = find_in_parent_folders()
}
include "stack" {
  path = "${get_repo_root()}/stacks/${basename(get_terragrunt_dir())}/terragrunt.hcl"
}

locals {
  local_build                 = false
  pre_plan_apply_hook_command = <<EOF
    RUNNING_PATH="$(pwd)"
    SOURCE_JSON_PATH=${get_repo_root()}/stacks/${basename(get_terragrunt_dir())}/source.json
    BASE_SOURCE_URL=$(jq -r '.base_source_url' "$SOURCE_JSON_PATH")
    REPO_ABS_PATH=$(dirname $(realpath $BASE_SOURCE_URL))
    BUILD_OUT_DIR="${get_working_dir()}/../dist"
    rm -rf "$BUILD_OUT_DIR" && mkdir "$BUILD_OUT_DIR"

    echo "Creating adhoc backend build..."
    echo "==================================="
    echo "PATH: $RUNNING_PATH"
    echo "BASE_SOURCE_URL: $BASE_SOURCE_URL"
    echo "REPO_ABS_PATH: $REPO_ABS_PATH"
    echo "BUILD_OUT_DIR: $BUILD_OUT_DIR"
    echo "==================================="
    echo

    pushd "$REPO_ABS_PATH" > /dev/null
    npm run build && npm run package && pushd dist && unzip -o build.zip -d "$BUILD_OUT_DIR/" && popd
    popd > /dev/null

    exit 0;
  EOF
}

terraform {
  before_hook "pre_plan_apply_stack" {
    commands    = local.local_build ? ["plan", "apply"] : []
    execute     = [get_env("SHELL", "/bin/bash"), "-ce", local.pre_plan_apply_hook_command]
    working_dir = "${get_working_dir()}/.."
  }
}

inputs = {
  cloudflare_enabled                = false
  api_gateway_custom_domain_enabled = false
}
