output "fqdn" { value = azurerm_mssql_server.this.fully_qualified_domain_name }
output "private_ip" { value = azurerm_private_endpoint.this.private_service_connection[0].private_ip_address }
