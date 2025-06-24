locals {
  stack_name  = basename(path_relative_to_include())
  environment = basename(dirname(path_relative_to_include()))
}

dependency "backend" {
  config_path = "${get_terragrunt_dir()}/../backend"

  # There are no outputs from frontend that backend would need to use.
  skip_outputs = true
}

# Probably redundant, but doesn't hurt
dependency "payment_plans" {
  config_path = "${get_terragrunt_dir()}/../payment_plans"

  mock_outputs = {
    spain_tax_rate = {
      id         = "spain_tax_rate_mock_id"
      inclusive  = true
      percentage = 21
    }
    subscription_tiers = {
      best = {
        name       = "Best Plan"
        price_eur  = 60
        price_id   = "best_price_id_mock"
        product_id = "best_product_id_mock"
      }
      better = {
        name       = "Better Plan"
        price_eur  = 25
        price_id   = "better_price_id_mock"
        product_id = "better_product_id_mock"
      }
      good = {
        name       = "Good Plan"
        price_eur  = 10
        price_id   = "good_price_id_mock"
        product_id = "good_product_id_mock"
      }
    }
    country_to_sms_cost_map = {
      ES = 1.3
    }
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate"]
}

inputs = {
  base_domain = "notifycal.com"
  # Production does not require any prefixes in the domain/URLs
  domain_prefix = local.environment == "prod" ? "private" : "private${local.environment}"
}
