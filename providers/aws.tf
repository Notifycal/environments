variable "_tags" {
  type = map(string)
}

variable "_aws_region" {
  type = string
}

locals {
  is_local_env = var._environment == "local"
  environment_iam_role_mapping = {
    dev = "arn:aws:iam::381492094204:role/ci-role"
    dev-dan = "arn:aws:iam::381492094204:role/ci-role"
    dev-sj11 = "arn:aws:iam::381492094204:role/ci-role"
    prod = "arn:aws:iam::222261726252:role/ci-role"
  }
}

provider "aws" {
  region = var._aws_region

  default_tags {
    tags = var._tags
  }

  assume_role {
    role_arn     = local.environment_iam_role_mapping[var._environment]
    session_name = "tofu-environment-${var._environment}"
  }

  skip_credentials_validation = local.is_local_env
  skip_metadata_api_check     = local.is_local_env
  skip_requesting_account_id  = local.is_local_env
  s3_use_path_style           = local.is_local_env
}

provider "aws" {
  alias = "shared_secrets"
  region = var._aws_region

  default_tags {
    tags = var._tags
  }

  skip_credentials_validation = local.is_local_env
  skip_metadata_api_check     = local.is_local_env
  skip_requesting_account_id  = local.is_local_env
  s3_use_path_style           = local.is_local_env
}
