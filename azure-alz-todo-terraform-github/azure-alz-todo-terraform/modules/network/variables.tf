variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "vnets" {
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
}
variable "tags" { type = map(string) }
