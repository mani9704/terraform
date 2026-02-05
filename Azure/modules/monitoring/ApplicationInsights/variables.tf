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

# Application Insights Variables
variable "application_insights_name" {
  description = "Name of the Application Insights resource"
  type        = string
}

variable "application_type" {
  description = "Type of Application Insights. Options: ios, java, MobileCenter, Node.JS, other, phone, store, universal, web"
  type        = string
  default     = "web"
}

variable "daily_data_cap_in_gb" {
  description = "Specifies the Application Insights component daily data volume cap in GB"
  type        = number
  default     = null
}

variable "daily_data_cap_notifications_disabled" {
  description = "Specifies if a notification email will be sent when the daily data volume cap is met"
  type        = bool
  default     = false
}

variable "retention_in_days" {
  description = "Specifies the retention period in days. Possible values are 30, 60, 90, 120, 180, 270, 365, 550 or 730"
  type        = number
  default     = 90
}

variable "sampling_percentage" {
  description = "Specifies the percentage of the data produced by the monitored application that is sampled for Application Insights telemetry"
  type        = number
  default     = null
}

variable "disable_ip_masking" {
  description = "By default the real client IP is masked as 0.0.0.0 in the logs. Use this argument to disable masking and log the real client IP"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace to link with Application Insights"
  type        = string
  default     = null
}

variable "local_authentication_disabled" {
  description = "Disable Non-Azure AD based Auth. Defaults to false"
  type        = bool
  default     = false
}

variable "internet_ingestion_enabled" {
  description = "Should the Application Insights component support ingestion over the Public Internet?"
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Should the Application Insights component support querying over the Public Internet?"
  type        = bool
  default     = true
}

variable "force_customer_storage_for_profiler" {
  description = "Should the Application Insights component force users to create their own storage account for profiling?"
  type        = bool
  default     = false
}

# Web Tests Variables
variable "web_tests" {
  description = "List of Application Insights Web Tests (Availability Tests) to create"
  type = list(object({
    name          = string
    kind          = string # "ping" or "multistep"
    configuration = string # XML configuration for the test
    frequency     = optional(number, 300) # Test frequency in seconds
    timeout       = optional(number, 60) # Test timeout in seconds
    enabled       = optional(bool, true)
    geo_locations = optional(list(string), ["us-ca-sjc-azr"])
    retry_enabled = optional(bool, false)
    description   = optional(string, null)
    tags          = optional(map(string), {})
  }))
  default = []
}

# API Keys Variables
variable "api_keys" {
  description = "List of API keys to create for Application Insights"
  type = list(object({
    name             = string
    read_permissions  = optional(list(string), [])
    write_permissions = optional(list(string), [])
  }))
  default = []
}

# Smart Detection Rules Variables
variable "smart_detection_rules" {
  description = "List of Smart Detection Rules to configure"
  type = list(object({
    name                            = string
    enabled                         = optional(bool, true)
    send_emails_to_subscription_owners = optional(bool, false)
    additional_email_recipients     = optional(list(string), [])
  }))
  default = []
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
