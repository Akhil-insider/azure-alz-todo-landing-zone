resource "azurerm_public_ip" "this" {
  for_each            = var.subnet_ids
  name                = "pip-nat-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
  tags                = var.tags
}
resource "azurerm_nat_gateway" "this" {
  for_each            = var.subnet_ids
  name                = "nat-${each.key}-egress"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"
  zones               = ["1"]
  tags                = var.tags
}
resource "azurerm_nat_gateway_public_ip_association" "this" {
  for_each             = var.subnet_ids
  nat_gateway_id       = azurerm_nat_gateway.this[each.key].id
  public_ip_address_id = azurerm_public_ip.this[each.key].id
}
resource "azurerm_subnet_nat_gateway_association" "this" {
  for_each       = var.subnet_ids
  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.this[each.key].id
}
