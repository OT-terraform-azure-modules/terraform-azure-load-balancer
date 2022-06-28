provider "azurerm" {
  features {}
}

module "res_group" {
  source                  = "git::git@gitlab.com:ot-azure/terraform/rg.git"
  resource_group_name     = "test-rg01"
  resource_group_location = "West Europe"
  lock_level_value        = ""
  tag_map = {
    Name = "AzureRG"
  }
}

module "vnet" {
  source                      = "OT-terraform-azure-modules/virtual-network/azure"
  vnet_name                   = "vnet01"
  resource_group_location     = module.res_group.resource_group_location
  resource_group_name         = module.res_group.resource_group_name
  address_space               = ["10.0.0.0/16"]
  tag_map                     = null
  create_ddos_protection_plan = false
  dns_servers                 = null
}

module "frontend_subnet" {
  source                  = "git@gitlab.com:ot-azure/terraform/subnet.git?ref=kritarth-V-0.1.1"
  subnet_address_prefixes = ["10.0.1.0/24"]
  subnet_name             = "loadba"
  resource_group_name     = module.res_group.resource_group_name
  vnet_name               = module.vnet.vnet_name
  service_endpoints       = null
}

module "backend_subnet" {
  source                  = "git@gitlab.com:ot-azure/terraform/subnet.git?ref=kritarth-V-0.1.1"
  subnet_address_prefixes = ["10.0.2.0/24"]
  subnet_name             = "loadba"
  resource_group_name     = module.res_group.resource_group_name
  vnet_name               = module.vnet.vnet_name
  service_endpoints       = null
}

module "azure_loadbalancer_module" {
  source                                 = "../"
  public_ip_name                         = "public_ip"
  resource_group_name                    = module.res_group.resource_group_name
  resource_group_location                = module.res_group.resource_group_location
  allocation_method                      = "Static"
  public_ip_address_sku                  = "Standard"
  lb_name                                = "lb"
  lb_sku                                 = "Standard"
  frontend_name                          = "frontend"
  type                                   = "private"
  frontend_subnet_id                     = join("\", \"", module.frontend_subnet.subnet_id)
  frontend_private_ip_address            = ""
  frontend_private_ip_address_allocation = "Dynamic"
  backend_pool_name                      = "backend"
  backend_address_name                   = ["back01", "back02"]
  backend_private_ip_address             = [azurerm_linux_virtual_machine.linux.private_ip_address]
  vnet_id                                = module.vnet.vnet_id
  remote_port = {
    ssh = ["Tcp", "22"]
  }
  protocol = "Tcp"
  lb_probe = {
    http = ["Tcp", "80", ""]
  }
  lb_probe_interval            = "5"
  lb_probe_unhealthy_threshold = "2"
  lb_port = {
    http = ["80", "Tcp", "80"]
  }
  lb_outbound_rule = {
    http = ["Tcp"]
  }
  tags = {
    env : "test"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "example-nic"
  location            = module.res_group.resource_group_location
  resource_group_name = module.res_group.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = join("\", \"", module.backend_subnet.subnet_id)
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "linux" {
  name                = "example-machine"
  resource_group_name = module.res_group.resource_group_name
  location            = module.res_group.resource_group_location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}
