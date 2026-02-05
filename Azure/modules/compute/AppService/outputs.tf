# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}

output "resource_group_id" {
  description = "ID of the resource group (if created)"
  value       = var.create_resource_group ? azurerm_resource_group.app_service_rg[0].id : null
}

# App Service Plan Outputs
output "app_service_plan_id" {
  description = "ID of the App Service Plan"
  value       = var.app_service_plan_id != null ? var.app_service_plan_id : (var.create_app_service_plan ? azurerm_service_plan.app_service_plan[0].id : null)
}

output "app_service_plan_name" {
  description = "Name of the App Service Plan"
  value       = var.app_service_plan_id != null ? null : (var.create_app_service_plan ? azurerm_service_plan.app_service_plan[0].name : null)
}

# App Service Outputs
output "app_service_id" {
  description = "ID of the App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.app_service_linux[0].id : azurerm_windows_web_app.app_service_windows[0].id
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = var.app_service_name
}

output "app_service_default_host_name" {
  description = "Default hostname of the App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.app_service_linux[0].default_hostname : azurerm_windows_web_app.app_service_windows[0].default_hostname
}

output "app_service_identity" {
  description = "Identity block of the App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.app_service_linux[0].identity : azurerm_windows_web_app.app_service_windows[0].identity
}

output "app_service_principal_id" {
  description = "Principal ID of the App Service (if managed identity is enabled)"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.app_service_linux[0].identity[0].principal_id : (length(azurerm_windows_web_app.app_service_windows[0].identity) > 0 ? azurerm_windows_web_app.app_service_windows[0].identity[0].principal_id : null)
}

output "app_service_url" {
  description = "URL of the App Service"
  value       = var.os_type == "Linux" ? "https://${azurerm_linux_web_app.app_service_linux[0].default_hostname}" : "https://${azurerm_windows_web_app.app_service_windows[0].default_hostname}"
}

# Deployment Slots Outputs
output "deployment_slot_ids" {
  description = "Map of deployment slot names to their IDs"
  value = var.os_type == "Linux" ? {
    for k, v in azurerm_linux_web_app_slot.app_service_slots_linux : k => v.id
  } : {
    for k, v in azurerm_windows_web_app_slot.app_service_slots_windows : k => v.id
  }
}

output "deployment_slot_hostnames" {
  description = "Map of deployment slot names to their hostnames"
  value = var.os_type == "Linux" ? {
    for k, v in azurerm_linux_web_app_slot.app_service_slots_linux : k => v.default_hostname
  } : {
    for k, v in azurerm_windows_web_app_slot.app_service_slots_windows : k => v.default_hostname
  }
}

output "deployment_slot_urls" {
  description = "Map of deployment slot names to their URLs"
  value = var.os_type == "Linux" ? {
    for k, v in azurerm_linux_web_app_slot.app_service_slots_linux : k => "https://${v.default_hostname}"
  } : {
    for k, v in azurerm_windows_web_app_slot.app_service_slots_windows : k => "https://${v.default_hostname}"
  }
}
