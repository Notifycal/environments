include "root" {
  path = find_in_parent_folders("root.hcl")
}
include "stack" {
  path = "${get_repo_root()}/stacks/${basename(get_terragrunt_dir())}/terragrunt.hcl"
}

locals {
  mailgun_domain = "nonprod.notifycal.com"
}

inputs = {
  observability = {
    alert_notifier = {
      slack_channel = "#dev-alerting"
    }
    alert_config = {
      treat_missing_data       = "ignore"
      notify_insufficient_data = false
    }
  }
  messaging_config = {
    enabled = false
  }
  mailgun_config = {
    base_url    = "https://api.eu.mailgun.net"
    domain_name = local.mailgun_domain
  }
  emailing_config = {
    enabled = true
    sender = {
      displayName = "Notifycal Dev"
      email       = "info@${local.mailgun_domain}"
    }
  }
  //TODO remove
  stripe_admin_api_key = "sk_test_51RW2zVPLMCn9OYH02HXU9c2Fv4zFxEBkcpyyRvWfuFAU2GkyE4U4MGD9adhcnEQdo15ZNt9aPnFA5KKgHXIbwv6p00GrIZsIu3"
}
