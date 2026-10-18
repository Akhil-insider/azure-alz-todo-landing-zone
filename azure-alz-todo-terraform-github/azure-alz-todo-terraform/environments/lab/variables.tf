variable "subscription_id" {
  description = "Azure subscription ID. Supply through environment/CI or a local untracked tfvars file."
  type        = string
  sensitive   = true
}
variable "location" {
  type    = string
  default = "East US"
}
variable "resource_group_name" {
  type    = string
  default = "rg-alz-todo-lab"
}
variable "tags" {
  type = map(string)
  default = {
    project     = "alz-todo-lab"
    environment = "lab"
    managed_by  = "terraform"
  }
}
variable "vnets" {
  description = "Hub/spoke address spaces and subnet maps. Confirm these do not overlap existing networks."
  type = map(object({
    address_space = list(string)
    subnets = map(object({
      address_prefixes = list(string)
      service_endpoints = optional(list(string), [])
      private_endpoint_network_policies = optional(string, "Disabled")
      delegation = optional(object({
        name = string
        service_delegation_name = string
        actions = optional(list(string), [])
      }))
    }))
  }))
  default = {
    hub = {
      address_space = ["10.0.0.0/16"]
      subnets = {
        AzureBastionSubnet = { address_prefixes = ["10.0.1.0/26"] }
        AzureFirewallSubnet = { address_prefixes = ["10.0.2.0/26"] }
        ApplicationGWSubnet = { address_prefixes = ["10.0.3.0/24"] }
        SharedSubnet = { address_prefixes = ["10.0.4.0/24"] }
      }
    }
    fe = {
      address_space = ["10.1.0.0/16"]
      subnets = { Subnet-FE = { address_prefixes = ["10.1.1.0/24"] } }
    }
    be = {
      address_space = ["10.2.0.0/16"]
      subnets = { Subnet-BE = { address_prefixes = ["10.2.1.0/24"] } }
    }
    db = {
      address_space = ["10.3.0.0/16"]
      subnets = { Subnet-DB = { address_prefixes = ["10.3.1.0/24"] } }
    }
  }
}
variable "enable_nat" {
  description = "NAT Gateway has recurring costs; enable only when required."
  type = bool
  default = false
}
variable "enable_firewall" {
  description = "Azure Firewall Premium has significant hourly costs; enable only after cost review."
  type = bool
  default = false
}
variable "enable_app_gateway" {
  description = "Application Gateway v2 incurs recurring costs; enable only after cost review."
  type = bool
  default = false
}
variable "enable_vms" {
  type    = bool
  default = false
}
variable "sql_admin_username" {
  type      = string
  sensitive = true
  default   = null
}
variable "sql_admin_password" {
  type      = string
  sensitive = true
  default   = null
}
variable "sql_server_name" {
  type    = string
  default = "tododbsrv-lab-change-me"
}
variable "sql_database_name" {
  type    = string
  default = "TodoDB"
}
variable "sql_location" {
  type    = string
  default = "Central US"
}
variable "domain_name" {
  description = "Optional existing GoDaddy domain, e.g. akhillabs.in"
  type        = string
  default     = "akhillabs.in"
}
variable "dns_record_name" {
  type    = string
  default = "todo"
}
variable "enable_godaddy_dns" {
  description = "Requires GoDaddy API key/secret as environment variables; do not store credentials in tfvars."
  type        = bool
  default     = false
}
