locals {
  stack_name  = basename(path_relative_to_include())
  environment = basename(dirname(path_relative_to_include()))
}

inputs = {
  base_domain = "notifycal.com"
  # Production does not require any prefixes in the domain/URLs
  # TODO: Fix this, with multi level domains
  domain_prefix = local.environment == "prod" ? "private" : "private${local.environment}"
  
  # TODO: Cloudflare TF provider ruleset issue stops us from using this
  # redirect_base_domains = [
  #   "notifycal.es",
  #   "notifical.es"
  # ]
}
