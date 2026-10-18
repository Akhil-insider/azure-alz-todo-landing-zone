resource "azurerm_resource_group" "lab" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "network" {
  source              = "../../modules/network"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  vnets               = var.vnets
  tags                = var.tags
}

module "nsg" {
  source              = "../../modules/nsg"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  subnet_ids          = module.network.subnet_ids
  tags                = var.tags
}

module "nat" {
  count               = var.enable_nat ? 1 : 0
  source              = "../../modules/nat"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  subnet_ids = {
    fe = module.network.subnet_ids["fe/Subnet-FE"]
    be = module.network.subnet_ids["be/Subnet-BE"]
  }
  tags = var.tags
}

module "firewall" {
  count               = var.enable_firewall ? 1 : 0
  source              = "../../modules/firewall"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  firewall_subnet_id  = module.network.subnet_ids["hub/AzureFirewallSubnet"]
  be_subnet_cidr      = var.vnets["be"].subnets["Subnet-BE"].address_prefixes[0]
  db_subnet_cidr      = var.vnets["db"].subnets["Subnet-DB"].address_prefixes[0]
  sql_private_ip      = "10.3.1.4"
  tags                = var.tags
}

module "routes" {
  count               = var.enable_firewall ? 1 : 0
  source              = "../../modules/routes"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  subnet_ids          = module.network.subnet_ids
  firewall_private_ip = module.firewall[0].private_ip
  tags                = var.tags
}

module "private_dns" {
  source              = "../../modules/private-dns"
  resource_group_name = azurerm_resource_group.lab.name
  vnet_ids = {
    fe = module.network.vnet_ids["fe"]
    be = module.network.vnet_ids["be"]
    db = module.network.vnet_ids["db"]
  }
  tags = var.tags
}

module "sql_private" {
  source              = "../../modules/sql-private"
  resource_group_name = azurerm_resource_group.lab.name
  location            = var.sql_location
  server_name         = var.sql_server_name
  database_name       = var.sql_database_name
  admin_username      = var.sql_admin_username
  admin_password      = var.sql_admin_password
  private_endpoint_subnet_id = module.network.subnet_ids["db/Subnet-DB"]
  private_dns_zone_id        = module.private_dns.zone_id
  tags = var.tags
}

# Optional modules are isolated to control costs. Enable after reviewing variables,
# backend pool settings, image credentials, and your actual current resource state.
module "linux_vms" {
  count               = var.enable_vms ? 1 : 0
  source              = "../../modules/linux-vm"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  subnet_ids = {
    fe = module.network.subnet_ids["fe/Subnet-FE"]
    be = module.network.subnet_ids["be/Subnet-BE"]
  }
  admin_username = "azureuser"
  tags            = var.tags
}

module "app_gateway" {
  count               = var.enable_app_gateway ? 1 : 0
  source              = "../../modules/app-gateway"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  subnet_id           = module.network.subnet_ids["hub/ApplicationGWSubnet"]
  backend_ip          = "10.1.1.4"
  tags                = var.tags
}

module "godaddy_dns" {
  count       = var.enable_godaddy_dns && var.enable_app_gateway ? 1 : 0
  source      = "../../modules/godaddy-dns"
  domain      = var.domain_name
  record_name = var.dns_record_name
  ip_address  = module.app_gateway[0].public_ip
  ttl         = 600
}
