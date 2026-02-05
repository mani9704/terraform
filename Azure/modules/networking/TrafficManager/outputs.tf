# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}

output "resource_group_id" {
  description = "ID of the resource group (if created)"
  value       = var.create_resource_group ? azurerm_resource_group.tm_rg[0].id : null
}

# Traffic Manager Profile Outputs
output "traffic_manager_profile_id" {
  description = "ID of the Traffic Manager profile"
  value       = azurerm_traffic_manager_profile.tm_profile.id
}

output "traffic_manager_profile_name" {
  description = "Name of the Traffic Manager profile"
  value       = azurerm_traffic_manager_profile.tm_profile.name
}

output "fqdn" {
  description = "Fully qualified domain name (FQDN) of the Traffic Manager profile"
  value       = azurerm_traffic_manager_profile.tm_profile.fqdn
}

output "traffic_routing_method" {
  description = "The routing method used by the Traffic Manager profile"
  value       = azurerm_traffic_manager_profile.tm_profile.traffic_routing_method
}

# Endpoint Outputs
output "azure_endpoints" {
  description = "Map of Azure endpoint names to their IDs"
  value       = { for k, v in azurerm_traffic_manager_azure_endpoint.azure_endpoints : k => v.id }
}

output "external_endpoints" {
  description = "Map of external endpoint names to their IDs"
  value       = { for k, v in azurerm_traffic_manager_external_endpoint.external_endpoints : k => v.id }
}

output "nested_endpoints" {
  description = "Map of nested endpoint names to their IDs"
  value       = { for k, v in azurerm_traffic_manager_nested_endpoint.nested_endpoints : k => v.id }
}

output "all_endpoints" {
  description = "Map of all endpoint names to their IDs"
  value = merge(
    { for k, v in azurerm_traffic_manager_azure_endpoint.azure_endpoints : k => v.id },
    { for k, v in azurerm_traffic_manager_external_endpoint.external_endpoints : k => v.id },
    { for k, v in azurerm_traffic_manager_nested_endpoint.nested_endpoints : k => v.id }
  )
}

# Monitor Configuration Outputs
output "monitor_config" {
  description = "Monitor configuration details"
  value = {
    protocol                     = azurerm_traffic_manager_profile.tm_profile.monitor_config[0].protocol
    port                         = azurerm_traffic_manager_profile.tm_profile.monitor_config[0].port
    path                         = azurerm_traffic_manager_profile.tm_profile.monitor_config[0].path
    interval_in_seconds          = azurerm_traffic_manager_profile.tm_profile.monitor_config[0].interval_in_seconds
    timeout_in_seconds           = azurerm_traffic_manager_profile.tm_profile.monitor_config[0].timeout_in_seconds
    tolerated_number_of_failures = azurerm_traffic_manager_profile.tm_profile.monitor_config[0].tolerated_number_of_failures
  }
}
