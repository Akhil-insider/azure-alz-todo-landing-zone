resource "azurerm_network_interface" "this" {
  for_each            = var.subnet_ids
  name                = "nic-todo-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = each.value
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}
resource "azurerm_linux_virtual_machine" "this" {
  for_each            = var.subnet_ids
  name                = each.key == "fe" ? "Todofevm" : "Todobevm"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B2s"
  admin_username      = var.admin_username
  network_interface_ids = [azurerm_network_interface.this[each.key].id]
  disable_password_authentication = true
  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand("~/.ssh/id_rsa.pub"))
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
  tags = var.tags
}
