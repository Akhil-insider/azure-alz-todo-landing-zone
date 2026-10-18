locals {
  rules = {
    fe = [
      { name="Allow-HTTP-From-AppGW", priority=200, direction="Inbound", access="Allow", protocol="Tcp", source_port_range="*", destination_port_range="80", source_address_prefix="10.0.3.0/24", destination_address_prefix="*" }
    ]
    be = [
      { name="Allow-FE-to-BE-8000", priority=200, direction="Inbound", access="Allow", protocol="Tcp", source_port_range="*", destination_port_range="8000", source_address_prefix="10.1.1.0/24", destination_address_prefix="*" }
    ]
    db = [
      { name="Allow-BE-to-DB-1433", priority=200, direction="Inbound", access="Allow", protocol="Tcp", source_port_range="*", destination_port_range="1433", source_address_prefix="10.2.1.0/24", destination_address_prefix="*" }
    ]
  }
}
resource "azurerm_network_security_group" "this" {
  for_each            = local.rules
  name                = "nsg-spoke-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  dynamic "security_rule" {
    for_each = each.value
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = {
    fe = var.subnet_ids["fe/Subnet-FE"]
    be = var.subnet_ids["be/Subnet-BE"]
    db = var.subnet_ids["db/Subnet-DB"]
  }
  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
