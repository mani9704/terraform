# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}

output "resource_group_id" {
  description = "ID of the resource group (if created)"
  value       = var.create_resource_group ? azurerm_resource_group.appinsights_rg[0].id : null
}

# Application Insights Outputs
output "application_insights_id" {
  description = "ID of the Application Insights resource"
  value       = azurerm_application_insights.appinsights.id
}

output "application_insights_name" {
  description = "Name of the Application Insights resource"
  value       = azurerm_application_insights.appinsights.name
}

output "application_insights_app_id" {
  description = "The App ID associated with this Application Insights component"
  value       = azurerm_application_insights.appinsights.app_id
}

output "application_insights_instrumentation_key" {
  description = "The Instrumentation Key for this Application Insights component"
  value       = azurerm_application_insights.appinsights.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "The Connection String for this Application Insights component"
  value       = azurerm_application_insights.appinsights.connection_string
  sensitive   = true
}

# Web Tests Outputs
output "web_test_ids" {
  description = "Map of web test names to their IDs"
  value = {
    for k, v in azurerm_application_insights_web_test.web_tests : k => v.id
  }
}

output "web_test_synthetic_monitor_ids" {
  description = "Map of web test names to their synthetic monitor IDs"
  value = {
    for k, v in azurerm_application_insights_web_test.web_tests : k => v.synthetic_monitor_id
  }
}

# API Keys Outputs
output "api_key_ids" {
  description = "Map of API key names to their IDs"
  value = {
    for k, v in azurerm_application_insights_api_key.api_keys : k => v.id
  }
}

output "api_keys" {
  description = "Map of API key names to their API keys (sensitive)"
  value = {
    for k, v in azurerm_application_insights_api_key.api_keys : k => v.api_key
  }
  sensitive = true
}

# Smart Detection Rules Outputs
output "smart_detection_rule_ids" {
  description = "Map of smart detection rule names to their IDs"
  value = {
    for k, v in azurerm_application_insights_smart_detection_rule.smart_detection_rules : k => v.id
  }
}
