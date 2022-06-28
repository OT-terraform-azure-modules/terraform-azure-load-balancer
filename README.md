
# Azure Load Balancer Terraform Module

[![Opstree Solutions][opstree_avatar]][opstree_homepage]

[Opstree Solutions][opstree_homepage]

  [opstree_homepage]: https://opstree.github.io/
  [opstree_avatar]: https://img.cloudposse.com/150x150/https://github.com/opstree.png

- This terraform module will create a Load Balancer
- This project is a part of opstree's ot-azure initiative for terraform modules

## Information
Azure Load Balancer operates at layer 4 of the Open Systems Interconnection (OSI) model. It's the single point of contact for clients. Load balancer distributes inbound flows that arrive at the load balancer's front end to backend pool instances. These flows are according to configured load-balancing rules and health probes. The backend pool instances can be Azure Virtual Machines or instances in a virtual machine scale set.

A public load balancer can provide outbound connections for virtual machines (VMs) inside your virtual network. These connections are accomplished by translating their private IP addresses to public IP addresses. Public Load Balancers are used to load balance internet traffic to your VMs.

An internal (or private) load balancer is used where private IPs are needed at the frontend only. Internal load balancers are used to load balance traffic inside a virtual network. A load balancer frontend can be accessed from an on-premises network in a hybrid scenario.


## Resources Supported
- [Resource Group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group)
- [Load Balancer](https://registry.terraform.io/modules/Azure/loadbalancer/azurerm/latest)
- [Vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network)
- [Subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet)
- [Windows Virtual Machine](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Network Interface](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface)
- [Public ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip)

## Module Usage

### Public Load Balancer

```
provider "azurerm" {
  features {}
}

module "res_group" {
  source                  = "git::git@gitlab.com:ot-azure/terraform/rg.git"
  resource_group_name     = "test-rg02"
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

module "subnet" {
  source                  = "git@gitlab.com:ot-azure/terraform/subnet.git?ref=kritarth-V-0.1.1"
  subnet_address_prefixes = ["10.0.1.0/24"]
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
  type                                   = "public"
  frontend_subnet_id                     = ""
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
    subnet_id                     = join("\", \"", module.subnet.subnet_id)
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
```

### Private Load Balancer

```
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
```
## Inputs
Name | Description | Type | Default | Required
-----|-------------|------|---------|:--------:
`resource_group_name` | The name of resource group in which the resources are created | string |  | Yes
`resource_group_location` | The name of resource group location in which the resource group is created | string |  | Yes |
`allocation_method` | Defines how an IP address is assigned.Options are Static or Dynamic | string |  | No | 
`Vnet_name` | The name of vnet | string |  | Yes |
`address_space` | The ip range of the vnet |  string |  | Yes |
`create_ddos_protection_plan` | Choose whether to have DDOS protection plan | string |  | Yes |
`dns_servers` | Specify if any dns servers | string |  | Yes |
`subnet_name` | The name of the subnet | string |  | Yes |
`subnet_address_prefixes` | The CIDR block for subnet | string |  | Yes |
`service_endpoints` | The ID of the Subnet Service Endpoint Storage Policy  | string |  | Yes |
`private_ip_address_allocation` | The allocation method for the Private IP Address used by this Load Balancer | string |  | No |
`admin_username` | The name of username for windows virtual machine | string |  | No |
`admin_password` | The password of windows virtual machine | string |  | No |
`caching` | Specifies the caching requirements for the Data Disk. Possible values include None, ReadOnly and ReadWrite | string | | No | 
`storage_account_type` | Choose the storage account type | string | Standard | No |
`publisher` | (Required) Specifies the publisher of the image | string  |  | Yes |
`sku` | (Required) Specifies the SKU of the image used to create the virtual machine. Changing this forces a new resource to be created | string |  | Yes |
`public_ip_address_sku` | Choose the sku for public ip | string | Standard | Yes |
`lb_name` | The name of load balancer | string |  | Yes |
`lb_sku` | The sku for load balancer | string |  | No |
`frontend_name` | The name of frontend ip configuration | string  |  | Yes |
`type` | The type of load balancer | string |  | Yes |
`frontend_subnet_id` | The id of subnet | string |  | Yes |
`frontend_private_ip_address` | The private ip address for frontend | string |  | No |
`frontend_private_ip_address_allocation` | The ip address allocation type for front end | string |  | No |
`backend_pool_name` | (Required) Specifies the name of the Backend Address Pool | string  |  | Yes |
`backend_address_name` | The name which should be used for this Backend Address Pool Address. Changing this forces a new Backend Address Pool Address to be created | list | | No |
`backend_private_ip_address` | The Static IP Address which should be allocated to this Backend Address Pool | list | | |
`remote_port` | Protocols to be used for remote vm access | map | | |
`lb_probe_interval` | The interval for health probes | number |  | No |
`lb_probe_unhealthy_threshold` | The threshold value for unhealthy probe | number |  | No
`lb_port` | The port for load balancer | map |  | Yes
`protocol` | The transport protocol for the external endpoint | string | | No |
`tags` | A map of tags to add to all resources | map |  | No |
`lb_outbound_rule` | Specifies the name of the Outbound Rule | map | | Yes |


## Outputs

Name | Description
-----|:----------:
`azure_lb_id` | The ID of azure load balancer |
`azure_frontend_ip_configuration_id` | The for frontend ip configuration for azure lb |
`azure_backend_address_pool_id` | The id for backend address pool for azure lb |
`azure_lb_nat_rule_id` | The for nat rule for azure lb |
`azure_lb_probe_id` | The id for lb probe for azure lb |
`azure_lb_rule_id` | The id for lb rule for azure lb |













## Contributors

- [@name](link)

