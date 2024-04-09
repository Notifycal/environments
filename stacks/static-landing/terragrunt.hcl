locals {
  stack_name = basename(path_relative_to_include())
  environment = basename(dirname(path_relative_to_include()))
}

inputs = {
  bucket_name = "notifycal-${local.stack_name}-${local.environment}"
}