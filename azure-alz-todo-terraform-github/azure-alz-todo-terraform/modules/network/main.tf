resource "azurerm_virtual_network" "this" {
  for_each            = var.vnets
  name                = each.key == "hub" ? "HubVnet" : each.key == "fe" ? "Spoke-FE-Vnet" : each.key == "be" ? "Spoke-BE-VNet" : "Spoke-DB-VNet"
  address_space       = each.value.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

locals {
  subnet_instances = {
    for item in flatten([
      for vnet_key, vnet in var.vnets : [
        for subnet_key, subnet in vnet.subnets : {
          key       = "${vnet_key}/${subnet_key}"
          vnet_key  = vnet_key
          name      = subnet_key
          config    = subnet
        }
      ]
    ]) : item.key => item
  }
}

resource "azurerm_subnet" "this" {
  for_each             = local.subnet_instances
  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this[each.value.vnet_key].name
  address_prefixes     = each.value.config.address_prefixes
  service_endpoints    = each.value.config.service_endpoints
  private_endpoint_network_policies = each.value.config.private_endpoint_network_policies

  dynamic "delegation" {
    for_each = each.value.config.delegation == null ? [] : [each.value.config.delegation]
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation_name
        actions = delegation.value.actions
      }
    }
  }
}
