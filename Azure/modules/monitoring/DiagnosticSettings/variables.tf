# Diagnostic Settings Variables
variable "diagnostic_settings" {
  description = "List of diagnostic settings to create for different Azure resources"
  type = list(object({
    name = string # Name of the diagnostic setting

    # Target resource
    target_resource_id = string # Resource ID of the target resource (e.g., VM, App Service, Storage Account, etc.)

    # Destination options (at least one must be specified)
    log_analytics_workspace_id     = optional(string, null) # Log Analytics Workspace ID
    eventhub_name                  = optional(string, null) # Event Hub name
    eventhub_authorization_rule_id = optional(string, null) # Event Hub authorization rule ID
    storage_account_id             = optional(string, null) # Storage Account ID
    partner_solution_id            = optional(string, null) # Partner solution ID

    # Log categories with retention policies
    log_categories = optional(list(object({
      category       = string
      category_group = optional(string, null)
      retention_policy = object({
        enabled = optional(bool, false)
        days    = optional(number, 0)
      })
    })), [])

    # Metric categories with retention policies
    metric_categories = optional(list(object({
      category = string
      enabled  = optional(bool, true)
      retention_policy = object({
        enabled = optional(bool, false)
        days    = optional(number, 0)
      })
    })), [])

    # Legacy support - Simple lists (for backward compatibility)
    legacy_logs    = optional(list(string), []) # Simple list of log category names
    legacy_metrics = optional(list(string), []) # Simple list of metric category names
  }))
  default = []
}
