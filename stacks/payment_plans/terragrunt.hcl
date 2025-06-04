dependency "env_secrets" {
  config_path = "${get_terragrunt_dir()}/../env_secrets"

  mock_outputs = {
    google_oauth_client_id     = "mock-client-id"
    google_oauth_client_secret = "mock-client-secret"
    google_oauth_redirect_url  = "http://mock.redirect.url"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate"]
}

inputs = {
  subscription_tiers = {
    good = {
      name        = "Good Plan"
      description = "Basic plan"
      price_cents = 1000 # €10.00
    }
    better = {
      name        = "Better Plan"
      description = "Better plan"
      price_cents = 2500 # €25.00
    }
    best = {
      name        = "Best Plan"
      description = "Best plan"
      price_cents = 6000 # €60.00
    }
  }
  currency             = "eur"
  spain_vat_percentage = 21.0

  stripe_admin_api_key = dependency.env_secrets.outputs.stripe_admin_api_key
}

exclude {
  if                   = true
  actions              = ["all"]
  exclude_dependencies = true
}
