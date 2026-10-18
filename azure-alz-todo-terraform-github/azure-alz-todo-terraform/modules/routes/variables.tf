variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "subnet_ids" { type = map(string) }
variable "firewall_private_ip" { type = string }
variable "tags" { type = map(string) }
