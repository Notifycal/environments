include "root" {
  path = find_in_parent_folders("root.hcl")
}
include "stack" {
  path = "${get_repo_root()}/stacks/${basename(get_terragrunt_dir())}/terragrunt.hcl"
}

locals {
  mailgun_domain = "notifycal.com"
}

inputs = {
  observability = {
    alert_notifier = {
      slack_channel = "#prod-alerting"
    }
    alert_config = {
      treat_missing_data       = "missing"
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
      displayName = "Notifycal"
      email       = "info@${local.mailgun_domain}"
    }
  }
  deletion_protection_enabled = true
}
