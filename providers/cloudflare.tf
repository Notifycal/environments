variable "cloudflare_api_token" {
  sensitive = true
  type      = string
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
