# Resource Group Variables
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "create_resource_group" {
  description = "Whether to create a new resource group"
  type        = bool
  default     = false
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

# Virtual Network Variables
variable "virtual_network_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network (CIDR notation)"
  type        = list(string)
}

variable "dns_servers" {
  description = "List of DNS servers IP addresses"
  type        = list(string)
  default     = []
}

# Subnet Variables
variable "subnets" {
  description = "List of subnets to create"
  type = list(object({
    name                                          = string
    address_prefixes                              = list(string)
    service_endpoints                             = optional(list(string))
    service_endpoint_policy_ids                   = optional(list(string))
    private_endpoint_network_policies_enabled     = optional(bool)
    private_link_service_network_policies_enabled = optional(bool)
    delegation = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = optional(list(string))
      })
    })))
    create_nsg = optional(bool, false)
    nsg_rules = optional(list(object({
      name                                       = string
      priority                                   = number
      direction                                  = string
      access                                     = string
      protocol                                   = string
      source_port_range                          = optional(string)
      source_port_ranges                         = optional(list(string))
      destination_port_range                     = optional(string)
      destination_port_ranges                    = optional(list(string))
      source_address_prefix                      = optional(string)
      source_address_prefixes                    = optional(list(string))
      destination_address_prefix                 = optional(string)
      destination_address_prefixes               = optional(list(string))
      source_application_security_group_ids      = optional(list(string))
      destination_application_security_group_ids = optional(list(string))
    })), [])
    nsg_tags = optional(map(string), {})
  }))
}

variable "create_nsgs" {
  description = "Whether to create Network Security Groups for subnets that have create_nsg = true"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
