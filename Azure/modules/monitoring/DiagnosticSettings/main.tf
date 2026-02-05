# Create Diagnostic Settings for resources
resource "azurerm_monitor_diagnostic_setting" "diagnostic_settings" {
  for_each = { for setting in var.diagnostic_settings : setting.name => setting }

  name                           = each.value.name
  target_resource_id             = each.value.target_resource_id
  log_analytics_workspace_id     = lookup(each.value, "log_analytics_workspace_id", null)
  eventhub_name                  = lookup(each.value, "eventhub_name", null)
  eventhub_authorization_rule_id = lookup(each.value, "eventhub_authorization_rule_id", null)
  storage_account_id             = lookup(each.value, "storage_account_id", null)
  partner_solution_id            = lookup(each.value, "partner_solution_id", null)

  # Log categories - Enable/disable specific log categories
  dynamic "enabled_log" {
    for_each = lookup(each.value, "log_categories", [])
    content {
      category = enabled_log.value.category
      category_group = lookup(enabled_log.value, "category_group", null)

      retention_policy {
        enabled = lookup(enabled_log.value.retention_policy, "enabled", false)
        days    = lookup(enabled_log.value.retention_policy, "days", 0)
      }
    }
  }

  # Metric categories - Enable/disable specific metric categories
  dynamic "metric" {
    for_each = lookup(each.value, "metric_categories", [])
    content {
      category = metric.value.category
      enabled  = lookup(metric.value, "enabled", true)

      retention_policy {
        enabled = lookup(metric.value.retention_policy, "enabled", false)
        days    = lookup(metric.value.retention_policy, "days", 0)
      }
    }
  }

  # Legacy support - Log categories (simple list)
  dynamic "log" {
    for_each = lookup(each.value, "legacy_logs", [])
    content {
      category = log.value
      enabled  = true

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }

  # Legacy support - Metric categories (simple list)
  dynamic "metric" {
    for_each = lookup(each.value, "legacy_metrics", [])
    content {
      category = metric.value
      enabled  = true

      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }
}
