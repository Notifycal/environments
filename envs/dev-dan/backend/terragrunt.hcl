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
  disable_execute_api_endpoint  = false
  api_gateway_custom_domain_ttl = 60

  observability = null
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
      displayName = "Notifycal Dev Dan"
      email       = "info@${local.mailgun_domain}"
    }
  }
  api_gateway_logging = {
    data_trace_enabled       = true
    logging_level            = "INFO"
    execution_logs_retention = 7
    access_logs_retention    = 7
  }
  deletion_protection_enabled = false
}
