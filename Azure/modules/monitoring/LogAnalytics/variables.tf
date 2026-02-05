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
  description = "Azure region for resources"
  type        = string
}

# Log Analytics Workspace Variables
variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  type        = string
}

variable "sku" {
  description = "SKU for the Log Analytics Workspace. Options: Free, PerNode, PerGB2018, Standard, Premium, Standalone"
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "The workspace data retention in days. Possible values are 30, 60, 90, 120, 180, 270, 365, 550 or 730"
  type        = number
  default     = 30
}

variable "allow_resource_only_permissions" {
  description = "Whether to allow resource only permissions on the workspace"
  type        = bool
  default     = true
}

variable "daily_quota_gb" {
  description = "The workspace daily quota for ingestion in GB. Defaults to -1 (unlimited)"
  type        = number
  default     = null
}

variable "internet_ingestion_enabled" {
  description = "Should the Log Analytics Workspace support ingestion over the Public Internet?"
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Should the Log Analytics Workspace support querying over the Public Internet?"
  type        = bool
  default     = true
}

variable "local_authentication_disabled" {
  description = "Whether to disable local authentication and rely only on Azure AD authentication"
  type        = bool
  default     = false
}

variable "reservation_capacity_in_gb_per_day" {
  description = "The capacity reservation level in GB for this workspace. Must be in increments of 100 between 100 and 5000"
  type        = number
  default     = null
}

# Solutions Variables
variable "solutions" {
  description = "List of Log Analytics solutions to enable"
  type = list(object({
    solution_name = string
    publisher     = string
    product       = string
    tags          = optional(map(string), {})
  }))
  default = []
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
