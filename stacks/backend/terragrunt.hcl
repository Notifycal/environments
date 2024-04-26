locals {
  stack_name  = basename(path_relative_to_include())
  environment = basename(dirname(path_relative_to_include()))
}

inputs = {
  api_stage_name  = local.environment
  resource_suffix = local.environment
}
