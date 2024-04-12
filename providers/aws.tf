variable "_tags" {
  type = map(string)
}

variable "_aws_region" {
  type = string
}

locals {
  is_local_env = var.environment == "local"
}

provider "aws" {
  region = var._aws_region

  default_tags {
    tags = var._tags
  }
  skip_credentials_validation = local.is_local_env
  skip_metadata_api_check     = local.is_local_env
  skip_requesting_account_id  = local.is_local_env
  s3_use_path_style           = local.is_local_env
}
