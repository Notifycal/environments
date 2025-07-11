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

    mailgun_api_key = "mailgun_api_key"

    stripe_admin_api_key     = "stripe_admin_api_key"
    stripe_operating_api_key = "stripe_operating_api_key"

    vonage_api_key                             = "vonage_api_key"
    vonage_application_id                      = "vonage_application_id"
    vonage_auth_private_key                    = "vonage_auth_private_key"
    vonage_auth_private_key_ssm_parameter_name = "vonage_auth_private_key_ssm_parameter_name"
    vonage_webhook_jwt_signing_secret          = "vonage_webhook_jwt_signing_secret"

    jwt_config = {
      access = {
        algorithm  = "ES256"
        issuer     = "notifycal.com"
        expiration = "1h"
        audience   = "notifycal.com"
      }
      refresh = {
        algorithm  = "ES256"
        issuer     = "notifycal.com"
        expiration = "7d"
        audience   = "notifycal.com"
      }
    }
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate"]
}

dependency "payment_plans" {
  config_path = "${get_terragrunt_dir()}/../payment_plans"

  mock_outputs = {
    payment_plans = {
      tiers = {
        best = {
          credits             = 1000
          name                = "Best Plan"
          number_of_reminders = 46
          price_eur           = 60
          price_id            = "best_price_id_mock"
          product_id          = "best_product_id_mock"
        }
        better = {
          credits             = 350
          name                = "Better Plan"
          number_of_reminders = 19
          price_eur           = 25
          price_id            = "better_price_id_mock"
          product_id          = "better_product_id_mock"
        }
        good = {
          credits             = 100
          name                = "Good Plan"
          number_of_reminders = 7
          price_eur           = 10
          price_id            = "good_price_id_mock"
          product_id          = "good_product_id_mock"
        }
      }
      topups = {
        single = {
          credits             = 90
          name                = "Single Topup"
          number_of_reminders = 9
          price_eur           = 12
          price_id            = "topup_single_price_id_mock"
          product_id          = "topup_single_product_id_mock"
        }
      }
    }
    spain_tax_config = {
      id         = "spain_tax_id_mock"
      percentage = 21
      inclusive  = true
    }
    country_to_sms_cost_map = {
      ES = 1.3
    }
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate"]
}

inputs = {
  base_domain = local.base_domain

  api_stage_name  = local.environment
  resource_suffix = local.environment

  # Production does not require any prefixes in the domain/URLs
  domain_prefix = local.environment == "prod" ? "api" : "api${local.environment}"

  frontend_domain = format("https://%s.%s",
    local.environment == "prod" ? "private" : "private${local.environment}",
    local.base_domain
  )
  # For CORS
  allowed_origins = compact([
    local.frontend_domain,
    startswith(local.environment, "dev") ? "http://localhost:5173" : null
  ])

  jwt_config = dependency.env_secrets.outputs.jwt_config
  jwt_keys   = dependency.env_secrets.outputs.jwt_keys

  google_oauth_config = {
    client_id     = dependency.env_secrets.outputs.google_oauth_client_id
    client_secret = dependency.env_secrets.outputs.google_oauth_client_secret
    redirect_url_list = compact([
      dependency.env_secrets.outputs.google_oauth_redirect_url,
      startswith(local.environment, "dev") ? "http://localhost:5173" : null
    ])
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

  payment_plans                    = dependency.payment_plans.outputs.payment_plans
  tax_id                           = dependency.payment_plans.outputs.spain_tax_config.id
  customer_portal_configuration_id = dependency.payment_plans.outputs.customer_portal_configuration_id
  country_to_sms_cost_map          = dependency.payment_plans.outputs.country_to_sms_cost_map

  stripe_operating_api_key = dependency.env_secrets.outputs.stripe_operating_api_key
  stripe_admin_api_key     = dependency.env_secrets.outputs.stripe_admin_api_key
}
