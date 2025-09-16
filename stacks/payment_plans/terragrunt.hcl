dependency "env_secrets" {
  config_path = "${get_terragrunt_dir()}/../env_secrets"

  mock_outputs = {
    google_oauth_client_id     = "mock-client-id"
    google_oauth_client_secret = "mock-client-secret"
    google_oauth_redirect_url  = "http://mock.redirect.url"
  }

  mock_outputs_allowed_terraform_commands = ["init", "providers", "validate"]
}

locals {
  plan_price_cents = {
    good   = 1600 # €16.00
    better = 4400 # €44.00
    best   = 9900 # €99.00
  }

  # --- Included ES messages per tier (ES used as a reference to simplify calculation). ---
  working_days_per_month = 20
  included_es_sms = {
    good   = 4 * local.working_days_per_month
    better = 15 * local.working_days_per_month
    best   = 60 * local.working_days_per_month
  }

  # --- Credit policy baseline ---
  # Use an ES baseline of 5 credits per ES SMS for clean integers and simple mental maths.
  credits_per_sms_base_es = 5

  # --- Country cost multipliers using an integer scale to avoid decimals ---
  # Represent country multipliers as integers over `multiplier_scale`, e.g. FR = 2.5 × ES.
  multiplier_scale = 10
  country_multiplier_scaled = {
    ES = 10 # 1.0× ES
    # FR = 25 # 2.5× ES # Uncomment when France is supported
  }

  # --- Derived: credits per SMS by country ---
  # Equation: credits_per_sms[country] = credits_per_sms_base_es * (country_multiplier_scaled / multiplier_scale).
  credits_per_sms_by_country = {
    for country, country_multiplier_scaled in local.country_multiplier_scaled :
    country => local.credits_per_sms_base_es * (country_multiplier_scaled / local.multiplier_scale)
  }

  # --- Derived: credits included per tier ---
  credits_per_tier = {
    for tier, sms in local.included_es_sms :
    tier => sms * local.credits_per_sms_base_es
  }

  # --- Top-up derived from Good's €/SMS (ES) and a fixed pack size in ES-SMS equivalents ---
  unit_price_cents_per_es_sms_from_good = local.plan_price_cents["good"] / local.included_es_sms["good"] # 1600 / 80 = 20 cents/sms
  topup_included_es_sms                 = 100
  topup_single_price_cents              = local.unit_price_cents_per_es_sms_from_good * local.topup_included_es_sms # 20 cents * 100 sms = 2000 cents 
  topup_single_credits                  = local.topup_included_es_sms * local.credits_per_sms_base_es               # 100 sms * 50 credits(1 sms to ES number) = 500 credits
}

inputs = {
  subscription_tiers = {
    good = {
      name        = "Solo"
      description = "${local.credits_per_tier["good"]} monthly credits"
      price_cents = local.plan_price_cents["good"]
      credits     = local.credits_per_tier["good"]
    }
    better = {
      name        = "Team"
      description = "${local.credits_per_tier["better"]} monthly credits"
      price_cents = local.plan_price_cents["better"]
      credits     = local.credits_per_tier["better"]
    }
    best = {
      name        = "Pro"
      description = "${local.credits_per_tier["best"]} monthly credits"
      price_cents = local.plan_price_cents["best"]
      credits     = local.credits_per_tier["best"]
    }
  }
  topups = {
    single = {
      name        = "Topup"
      description = "${local.topup_single_credits} additional credits"
      price_cents = local.topup_single_price_cents
      credits     = local.topup_single_credits
    }
  }
  country_to_sms_cost_map = local.credits_per_sms_by_country
  currency                = "eur"
  spain_vat_percentage    = 21.0

  stripe_admin_api_key = dependency.env_secrets.outputs.stripe_admin_api_key
}

exclude {
  if                   = true
  actions              = ["all"]
  exclude_dependencies = true
}
