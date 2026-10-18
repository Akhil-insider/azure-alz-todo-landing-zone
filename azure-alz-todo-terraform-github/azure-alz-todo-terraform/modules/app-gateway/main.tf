resource "azurerm_public_ip" "this" {
  name                = "pip-appgw-todo"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}
resource "azurerm_application_gateway" "this" {
  name                = "agw-todo-prod"
  location            = var.location
  resource_group_name = var.resource_group_name
  zones               = ["1", "2", "3"]
  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
    capacity = 1
  }
  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.subnet_id
  }
  frontend_port {
    name = "http-port"
    port = 80
  }
  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.this.id
  }
  backend_address_pool {
    name  = "pool-todo-frontend"
    ip_addresses = [var.backend_ip]
  }
  probe {
    name                = "http-health"
    protocol            = "Http"
    path                = "/"
    host                = "127.0.0.1"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    match { status_code = ["200-399"] }
  }
  backend_http_settings {
    name                  = "http-backend-80"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = "http-health"
  }
  http_listener {
    name                           = "listener-todo-http"
    frontend_ip_configuration_name = "public-frontend"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }
  request_routing_rule {
    name                       = "rule-todo-http"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "listener-todo-http"
    backend_address_pool_name  = "pool-todo-frontend"
    backend_http_settings_name = "http-backend-80"
  }
  tags = var.tags
}
