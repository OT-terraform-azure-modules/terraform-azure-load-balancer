resource "azurerm_public_ip" "azurelb" {
  count               = var.type == "public" ? 1 : 0
  name                = var.public_ip_name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  allocation_method   = var.allocation_method
  sku                 = var.public_ip_address_sku
  tags                = var.tags
}

resource "azurerm_lb" "azurelb" {
  name                = var.lb_name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  sku                 = var.lb_sku
  tags                = var.tags

  frontend_ip_configuration {
    name                          = var.frontend_name
    public_ip_address_id          = var.type == "public" ? join("", azurerm_public_ip.azurelb.*.id) : ""
    subnet_id                     = var.frontend_subnet_id
    private_ip_address            = var.frontend_private_ip_address
    private_ip_address_allocation = var.frontend_private_ip_address_allocation

  }
}

resource "azurerm_lb_nat_rule" "azurelb" {
  count                          = length(var.remote_port)
  name                           = "VM-${count.index}"
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.azurelb.id
  protocol                       = var.protocol
  frontend_port                  = "1${count.index + 1}"
  backend_port                   = element(var.remote_port[element(keys(var.remote_port), count.index)], 1)
  frontend_ip_configuration_name = var.frontend_name
}

resource "azurerm_lb_probe" "azurelb" {
  count               = length(var.lb_probe)
  name                = element(keys(var.lb_probe), count.index)
  loadbalancer_id     = azurerm_lb.azurelb.id
  protocol            = element(var.lb_probe[element(keys(var.lb_probe), count.index)], 0)
  port                = element(var.lb_probe[element(keys(var.lb_probe), count.index)], 1)
  interval_in_seconds = var.lb_probe_interval
  number_of_probes    = var.lb_probe_unhealthy_threshold
  request_path        = element(var.lb_probe[element(keys(var.lb_probe), count.index)], 2)
}


resource "azurerm_lb_rule" "azurelb" {
  count                          = length(var.lb_port)
  name                           = element(keys(var.lb_port), count.index)
  loadbalancer_id                = azurerm_lb.azurelb.id
  protocol                       = element(var.lb_port[element(keys(var.lb_port), count.index)], 1)
  frontend_port                  = element(var.lb_port[element(keys(var.lb_port), count.index)], 0)
  backend_port                   = element(var.lb_port[element(keys(var.lb_port), count.index)], 2)
  frontend_ip_configuration_name = var.frontend_name
  enable_floating_ip             = false
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.azurelb.id]
  idle_timeout_in_minutes        = 4
  probe_id                       = element(azurerm_lb_probe.azurelb.*.id, count.index)
  disable_outbound_snat          = true
}

resource "azurerm_lb_outbound_rule" "azurelb" {
  count                   = var.type == "public" ? length(var.lb_outbound_rule) : 0
  name                    = element(keys(var.lb_outbound_rule), count.index)
  loadbalancer_id         = azurerm_lb.azurelb.id
  protocol                = element(var.lb_outbound_rule[element(keys(var.lb_outbound_rule), count.index)], 1)
  backend_address_pool_id = azurerm_lb_backend_address_pool.azurelb.id

  frontend_ip_configuration {
    name = var.frontend_name
  }

}

resource "azurerm_lb_backend_address_pool" "azurelb" {
  name            = var.backend_pool_name
  loadbalancer_id = azurerm_lb.azurelb.id
}


