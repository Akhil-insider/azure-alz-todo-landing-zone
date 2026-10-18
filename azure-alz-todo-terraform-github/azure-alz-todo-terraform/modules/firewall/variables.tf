variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "firewall_subnet_id" { type = string }
variable "be_subnet_cidr" { type = string }
variable "db_subnet_cidr" { type = string }
variable "sql_private_ip" { type = string }
variable "tags" { type = map(string) }
