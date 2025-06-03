locals {
  stack_name  = basename(path_relative_to_include())
  environment = basename(dirname(path_relative_to_include()))

  # Can this be a global setting for all stacks? Does it make sense?
  base_domain = "notifycal.com"
}

dependency "env_secrets" {
  config_path = "${get_terragrunt_dir()}/../env_secrets"

  mock_outputs = {
    google_oauth_client_id     = "mock-client-id"
    google_oauth_client_secret = "mock-client-secret"
    google_oauth_redirect_url  = "http://mock.redirect.url"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate"]
}

dependency "payment_plans" {
  config_path = "${get_terragrunt_dir()}/../payment_plans"
}

inputs = {
  base_domain = local.base_domain

  api_stage_name  = local.environment
  resource_suffix = local.environment

  # Production does not require any prefixes in the domain/URLs
  domain_prefix = local.environment == "prod" ? "api" : "api${local.environment}"

  # For CORS
  frontend_domain = format(
    "https://%s.%s",
    local.environment == "prod" ? "private" : "private${local.environment}",
    local.base_domain
  )

  google_oauth_config = {
    client_id     = dependency.env_secrets.outputs.google_oauth_client_id
    client_secret = dependency.env_secrets.outputs.google_oauth_client_secret
    redirect_url  = dependency.env_secrets.outputs.google_oauth_redirect_url
  }

  vonage_auth_config = {
    application_id             = dependency.env_secrets.outputs.vonage_application_id
    private_key_secret_path    = dependency.env_secrets.outputs.vonage_auth_private_key_ssm_parameter_name
    webhook_jwt_signing_secret = dependency.env_secrets.outputs.vonage_webhook_jwt_signing_secret
    api_key                    = dependency.env_secrets.outputs.vonage_api_key
  }

  mailgun_auth = {
    api_key = dependency.env_secrets.outputs.mailgun_api_key
  }

  subcription_tiers        = dependency.payment_plans.outputs.subscription_tiers
  stripe_operating_api_key = dependency.env_secrets.outputs.stripe_operating_api_key
}
