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
  deletion_protection_enabled = false
}
