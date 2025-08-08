locals {
  stack_name  = basename(path_relative_to_include())
  environment = basename(dirname(path_relative_to_include()))
}

dependency "url_registry" {
  config_path = "${get_terragrunt_dir()}/../url_registry"

  mock_outputs = {
    frontend_url = {
      domain_prefix = "fake-domain-prefix"
      # This has to be real because it maps to a data source DNS Zone in Cloudflare, plan will fail otherwise
      base_domain = "notifycal.com"
    }
  }

  mock_outputs_allowed_terraform_commands = ["init", "providers", "validate", "plan", "destroy"]
}

# Probably redundant, but doesn't hurt
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

  mock_outputs_allowed_terraform_commands = ["init", "providers", "validate"]
}

inputs = {
  base_domain   = dependency.url_registry.outputs.frontend_url.base_domain
  domain_prefix = dependency.url_registry.outputs.frontend_url.domain_prefix
}
