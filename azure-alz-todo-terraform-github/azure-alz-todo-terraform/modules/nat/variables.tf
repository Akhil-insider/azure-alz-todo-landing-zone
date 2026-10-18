variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "subnet_ids" { type = map(string) }
variable "tags" { type = map(string) }
