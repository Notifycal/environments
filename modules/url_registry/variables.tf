variable "environment" {
  type = string
}

variable "urls_to_register" {
  description = "URLs to register in SSM. Keys need to match stack names but using hyphens instead of underscores."
  type = object({
    frontend = string
    backend = string
    static-landing = string
  })
}
