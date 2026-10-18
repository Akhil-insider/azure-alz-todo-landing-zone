locals {
  routes = {
    be_to_db = { route_table_key = "be", address_prefix = "10.3.1.0/24" }
    db_to_be = { route_table_key = "db", address_prefix = "10.2.1.0/24" }
    fe_to_be = { route_table_key = "fe", address_prefix = "10.2.1.0/24" }
  }
}
resource "azurerm_route_table" "this" {
  for_each            = toset(["fe", "be", "db"])
  name                = "rt-spoke-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
resource "azurerm_route" "this" {
  for_each               = local.routes
  name                   = "route-${replace(each.key, "_", "-")}-via-fw"
  resource_group_name    = var.resource_group_name
  route_table_name       = azurerm_route_table.this[each.value.route_table_key].name
  address_prefix         = each.value.address_prefix
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.firewall_private_ip
}
resource "azurerm_subnet_route_table_association" "this" {
  for_each = {
    fe = var.subnet_ids["fe/Subnet-FE"]
    be = var.subnet_ids["be/Subnet-BE"]
    db = var.subnet_ids["db/Subnet-DB"]
  }
  subnet_id      = each.value
  route_table_id = azurerm_route_table.this[each.key].id
}
