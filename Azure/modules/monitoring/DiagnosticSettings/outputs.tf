# Diagnostic Settings Outputs
output "diagnostic_setting_ids" {
  description = "Map of diagnostic setting names to their IDs"
  value = {
    for k, v in azurerm_monitor_diagnostic_setting.diagnostic_settings : k => v.id
  }
}

output "diagnostic_settings" {
  description = "Map of diagnostic setting names to their full configuration"
  value = {
    for k, v in azurerm_monitor_diagnostic_setting.diagnostic_settings : k => {
      id                         = v.id
      name                       = v.name
      target_resource_id         = v.target_resource_id
      log_analytics_workspace_id = v.log_analytics_workspace_id
      storage_account_id         = v.storage_account_id
      eventhub_name              = v.eventhub_name
    }
  }
}
