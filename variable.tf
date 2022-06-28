variable "public_ip_name" {
  description = "Name of public ip"
  type        = string
}

variable "resource_group_location" {
  description = "The location/region where the core network will be created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group where the load balancer resources will be imported"
  type        = string
}

variable "allocation_method" {
  description = "Defines how an IP address is assigned.Options are Static or Dynamic"
  type        = string
}

variable "public_ip_address_sku" {
  description = "The SKU of the Azure Public IP.Optionsare Basic and Standard"
  type        = string
}

variable "type" {
  description = "Defined if the loadbalancer is private or public"
  type        = string
}

variable "tags" {
  type = map(string)

}

variable "lb_name" {
  description = " (Required) Name of the load balancer. If it is set, the 'prefix' variable will be ignored."
  type        = string
}


variable "lb_sku" {
  description = "The SKU of the Azure Load Balancer. Accepted values are Basic and Standard."
  type        = string
}

variable "frontend_name" {
  description = "Specifies the name of the frontend ip configuration."
  type        = string
}
variable "frontend_subnet_id" {
  description = " Frontend subnet id to use when in private mode"
  type        = string
}
variable "frontend_private_ip_address" {
  description = "Private ip address to assign to frontend."
  type        = string
}

variable "frontend_private_ip_address_allocation" {
  description = "Frontend ip allocation type (Static or Dynamic)"
  type        = string
}

variable "backend_pool_name" {
  description = "Name of backend pool"
  type        = string
}

variable "backend_address_name" {
  type        = list(string)
  description = "The name which should be used for this Backend Address Pool Address. Changing this forces a new Backend Address Pool Address to be created."
}

variable "vnet_id" {
  type        = string
  description = "The ID of the Virtual Network within which the Backend Address Pool should exist."
}

variable "backend_private_ip_address" {
  type        = list(string)
  description = "The Static IP Address which should be allocated to this Backend Address Pool."
}

variable "remote_port" {
  description = "Protocols to be used for remote vm access."
  type        = map(any)
}

variable "protocol" {
  description = "The transport protocol for the external endpoint."
  type        = string
}

variable "lb_probe" {
  description = "Protocols to be used for lb health probes."
  type        = map(any)
}

variable "lb_probe_unhealthy_threshold" {
  description = "Number of times the load balancer health probe has an unsuccessful attempt before considering the endpoint unhealthy."
  type        = number
}

variable "lb_probe_interval" {
  description = "Interval in seconds the load balancer health probe rule does a check"
  type        = number
}

variable "lb_port" {
  description = "Protocols to be used for lb rules"
  type        = map(any)
}

variable "lb_outbound_rule" {
  description = "Specifies the name of the Outbound Rule"
  type        = map(any)
}

