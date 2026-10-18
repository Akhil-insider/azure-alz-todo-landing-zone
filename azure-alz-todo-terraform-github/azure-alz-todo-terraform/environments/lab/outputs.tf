output "resource_group_name" {
  value = azurerm_resource_group.lab.name
}
output "vnet_ids" {
  value = module.network.vnet_ids
}
output "subnet_ids" {
  value = module.network.subnet_ids
}
output "sql_fqdn" {
  value = module.sql_private.fqdn
}
output "sql_private_endpoint_ip" {
  value = module.sql_private.private_ip
}
output "application_gateway_public_ip" {
  value = var.enable_app_gateway ? module.app_gateway[0].public_ip : null
}
