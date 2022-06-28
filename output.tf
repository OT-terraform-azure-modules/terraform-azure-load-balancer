output "azurerm_public_ip_id" {
  value       = azurerm_public_ip.azurelb.*.id
  description = "The id for azure public ip for this lb"
}

output "azurerm_lb_id" {
  value       = azurerm_lb.azurelb.id
  description = "The id for azure lb"
}

output "azurerm_frontend_ip_configuration_id" {
  value       = azurerm_lb.azurelb.frontend_ip_configuration
  description = "The id for frontend ip configuration for azure lb"
}

output "azurerm_backend_address_pool_id" {
  value       = azurerm_lb_backend_address_pool.azurelb.id
  description = "The id for backend address pool for azure lb"
}

output "azurerm_lb_nat_rule_id" {
  value       = azurerm_lb_nat_rule.azurelb.*.id
  description = "The id for nat rule for azure lb"
}


output "azurerm_lb_probe_id" {
  value       = azurerm_lb_probe.azurelb.*.id
  description = "The id for lb probe for azure lb"
}


output "azurerm_lb_rule_id" {
  value       = azurerm_lb_rule.azurelb.*.id
  description = "The id for lb rule for azure lb"
}


output "azurerm_lb_outbound_rule_id" {
  value       = azurerm_lb_outbound_rule.azurelb.*.id
  description = "The id for outbound rule for azure lb"
}



