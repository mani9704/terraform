# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = var.create_resource_group ? azurerm_resource_group.vnet_rg[0].id : null
}

output "location" {
  description = "Location of the resources"
  value       = var.location
}

# Virtual Network Outputs
output "virtual_network_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.vnet.id
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.vnet.name
}

output "virtual_network_address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.vnet.address_space
}

# Subnet Outputs
output "subnet_ids" {
  description = "Map of subnet names to subnet IDs"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "subnet_names" {
  description = "List of subnet names"
  value       = [for k, v in azurerm_subnet.subnets : k]
}

output "subnet_details" {
  description = "Detailed information about all subnets"
  value = {
    for k, v in azurerm_subnet.subnets : k => {
      id               = v.id
      name             = v.name
      address_prefixes = v.address_prefixes
    }
  }
}

# Network Security Group Outputs
output "network_security_group_ids" {
  description = "Map of subnet names to NSG IDs (only for subnets with NSGs)"
  value = var.create_nsgs ? {
    for k, v in azurerm_network_security_group.nsgs : k => v.id
  } : {}
}

output "network_security_group_names" {
  description = "Map of subnet names to NSG names (only for subnets with NSGs)"
  value = var.create_nsgs ? {
    for k, v in azurerm_network_security_group.nsgs : k => v.name
  } : {}
}

# Convenience Outputs for Common Subnet Names
output "subnet_id" {
  description = "ID of the first subnet (for backward compatibility)"
  value       = length(azurerm_subnet.subnets) > 0 ? values(azurerm_subnet.subnets)[0].id : null
}

output "subnet_name" {
  description = "Name of the first subnet (for backward compatibility)"
  value       = length(azurerm_subnet.subnets) > 0 ? values(azurerm_subnet.subnets)[0].name : null
}
