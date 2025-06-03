include "root" {
  path = find_in_parent_folders("root.hcl")
}
include "stack" {
  path = "${get_repo_root()}/stacks/${basename(get_terragrunt_dir())}/terragrunt.hcl"
}

locals {
  mailgun_domain = "local.notifycal.com"
}

inputs = {
  frontend_domain                   = "http://localhost:5173"
  api_gateway_custom_domain_enabled = false

  observability              = null
  enable_xray_active_tracing = false
  enable_data_protection     = false

  messaging_config = {
    enabled = false
  }
  emailing_config = {
    enabled = false
    sender = {
      displayName = "Notifycal Dev"
      email       = "info@${local.mailgun_domain}"
    }
  }
  mailgun_config = {
    base_url    = "https://api.mailgun-notifycal.net"
    domain_name = local.mailgun_domain
  }
}
