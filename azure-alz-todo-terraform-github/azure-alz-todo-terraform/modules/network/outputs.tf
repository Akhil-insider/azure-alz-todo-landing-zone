output "vnet_ids" {
  value = { for k, v in azurerm_virtual_network.this : k => v.id }
}
output "subnet_ids" {
  value = { for k, v in azurerm_subnet.this : k => v.id }
}
