variable "environment" {
  type = string
}

variable "base_domain" {
  type    = string
  default = "notifycal.com"
}

variable "urls_to_register" {
  description = "URLs to register in SSM. Keys need to match stack names but using hyphens instead of underscores."
  type = object({
    backend = string
    frontend = object({
      domain_prefix = string
    })
    static-landing = object({
      domain_prefix = string
    })
  })
}
