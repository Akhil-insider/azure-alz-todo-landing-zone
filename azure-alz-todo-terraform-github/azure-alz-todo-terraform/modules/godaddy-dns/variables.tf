variable "domain" { type = string }
variable "record_name" { type = string }
variable "ip_address" { type = string }
variable "ttl" {
  type    = number
  default = 600
}
