# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}

output "resource_group_id" {
  description = "ID of the resource group (if created)"
  value       = var.create_resource_group ? azurerm_resource_group.law_rg[0].id : null
}

# Log Analytics Workspace Outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.law.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.law.name
}

output "log_analytics_workspace_primary_shared_key" {
  description = "The Primary shared key for the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.law.primary_shared_key
  sensitive   = true
}

output "log_analytics_workspace_secondary_shared_key" {
  description = "The Secondary shared key for the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.law.secondary_shared_key
  sensitive   = true
}

output "log_analytics_workspace_workspace_id" {
  description = "The Workspace (or Customer) ID for the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.law.workspace_id
}

# Solutions Outputs
output "solution_ids" {
  description = "Map of solution names to their IDs"
  value = {
    for k, v in azurerm_log_analytics_solution.law_solutions : k => v.id
  }
}
