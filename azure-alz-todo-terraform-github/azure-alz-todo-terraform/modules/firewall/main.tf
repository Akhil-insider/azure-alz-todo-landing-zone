resource "azurerm_public_ip" "this" {
  name                = "pip-hub-firewall"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}
resource "azurerm_firewall_policy" "this" {
  name                = "fwpol-hub-lab"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Premium"
  tags                = var.tags
}
resource "azurerm_firewall_policy_rule_collection_group" "network" {
  name               = "rcg-workload-network"
  firewall_policy_id = azurerm_firewall_policy.this.id
  priority           = 200

  network_rule_collection {
    name     = "allow-be-to-sql"
    priority = 200
    action   = "Allow"
    rule {
      name                  = "BE-to-SQL-1433"
      protocols             = ["TCP"]
      source_addresses      = [var.be_subnet_cidr]
      destination_addresses = [var.sql_private_ip]
      destination_ports     = ["1433"]
    }
  }
}
resource "azurerm_firewall" "this" {
  name                = "Hub-AzureFirewall"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Premium"
  firewall_policy_id  = azurerm_firewall_policy.this.id
  zones               = ["1", "2", "3"]
  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.this.id
  }
  tags = var.tags
}
