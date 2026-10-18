terraform {
  required_providers {
    godaddy = {
      source  = "n3integration/godaddy"
      version = "~> 1.0"
    }
  }
}
provider "godaddy" {
  key    = var.godaddy_api_key
  secret = var.godaddy_api_secret
}
variable "godaddy_api_key" {
  type      = string
  sensitive = true
}
variable "godaddy_api_secret" {
  type      = string
  sensitive = true
}
resource "godaddy_domain_record" "todo" {
  domain = var.domain
  name   = var.record_name
  type   = "A"
  data   = var.ip_address
  ttl    = var.ttl
}
