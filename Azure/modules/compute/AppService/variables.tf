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
  description = "Azure region where resources will be created"
  type        = string
}

# App Service Plan Variables
variable "create_app_service_plan" {
  description = "Whether to create a new App Service Plan"
  type        = bool
  default     = true
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan (used if create_app_service_plan is true)"
  type        = string
  default     = null
}

variable "app_service_plan_id" {
  description = "ID of existing App Service Plan (used if create_app_service_plan is false)"
  type        = string
  default     = null
}

variable "app_service_plan_os_type" {
  description = "OS type for App Service Plan (Linux or Windows)"
  type        = string
  default     = "Linux"
  validation {
    condition     = contains(["Linux", "Windows"], var.app_service_plan_os_type)
    error_message = "app_service_plan_os_type must be either 'Linux' or 'Windows'."
  }
}

variable "app_service_plan_sku_name" {
  description = "SKU name for App Service Plan (e.g., B1, S1, P1v2)"
  type        = string
  default     = "B1"
}

variable "app_service_plan_config" {
  description = "Additional configuration for App Service Plan"
  type = object({
    zone_balancing_enabled   = optional(bool, false)
    per_site_scaling_enabled = optional(bool, false)
  })
  default = {}
}

# App Service Variables
variable "app_service_name" {
  description = "Name of the App Service"
  type        = string
}

variable "os_type" {
  description = "OS type for App Service (must match App Service Plan OS type)"
  type        = string
  default     = "Linux"
  validation {
    condition     = contains(["Linux", "Windows"], var.os_type)
    error_message = "os_type must be either 'Linux' or 'Windows'."
  }
}

variable "https_only" {
  description = "Should the App Service require HTTPS"
  type        = bool
  default     = true
}

variable "enabled" {
  description = "Should the App Service be enabled"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Should public network access be enabled"
  type        = bool
  default     = true
}

variable "client_certificate_enabled" {
  description = "Should client certificates be enabled"
  type        = bool
  default     = false
}

variable "client_certificate_mode" {
  description = "Client certificate mode (Required, Optional, OptionalInteractiveUser)"
  type        = string
  default     = null
}

variable "client_certificate_exclusion_paths" {
  description = "Paths to exclude from client certificate requirement"
  type        = list(string)
  default     = null
}

# App Settings
variable "app_settings" {
  description = "Map of App Settings"
  type        = map(string)
  default     = {}
}

# Connection Strings
variable "connection_strings" {
  description = "List of connection strings"
  type = list(object({
    name  = string
    type  = string # APIHub, Custom, DocDb, EventHub, MySQL, NotificationHub, PostgreSQL, RedisCache, ServiceBus, SQLAzure, SQLServer
    value = string
  }))
  default = []
}

# Site Config
variable "site_config" {
  description = "Site configuration for App Service"
  type = object({
    always_on                                     = optional(bool, true)
    api_definition_url                            = optional(string, null)
    api_management_api_id                         = optional(string, null)
    app_command_line                              = optional(string, null)
    auto_heal_enabled                             = optional(bool, false)
    container_registry_managed_identity_client_id = optional(string, null)
    container_registry_use_managed_identity       = optional(bool, false)
    default_documents                             = optional(list(string), null)
    ftps_state                                    = optional(string, "Disabled")
    health_check_path                             = optional(string, null)
    health_check_eviction_time_in_min             = optional(number, null)
    http2_enabled                                 = optional(bool, false)
    ip_restriction_default_action                 = optional(string, "Allow")
    load_balancing_mode                           = optional(string, "LeastRequests")
    managed_pipeline_mode                         = optional(string, null)
    minimum_tls_version                           = optional(string, "1.2")
    remote_debugging_enabled                      = optional(bool, false)
    remote_debugging_version                      = optional(string, null)
    scm_minimum_tls_version                       = optional(string, "1.2")
    scm_use_main_ip_restriction                   = optional(bool, false)
    use_32_bit_worker                             = optional(bool, false)
    vnet_route_all_enabled                        = optional(bool, false)
    websockets_enabled                            = optional(bool, false)
    worker_count                                  = optional(number, null)
    windows_fx_version                            = optional(string, null)
    ip_restrictions = optional(list(object({
      action                    = optional(string, "Allow")
      ip_address                = optional(string, null)
      name                      = optional(string, null)
      priority                  = optional(number, null)
      service_tag               = optional(string, null)
      virtual_network_subnet_id = optional(string, null)
      headers = optional(object({
        x_azure_fdid      = optional(string, null)
        x_fd_health_probe = optional(string, null)
        x_forwarded_for   = optional(string, null)
        x_forwarded_host  = optional(string, null)
      }), null)
    })), [])
    scm_ip_restrictions = optional(list(object({
      action                    = optional(string, "Allow")
      ip_address                = optional(string, null)
      name                      = optional(string, null)
      priority                  = optional(number, null)
      service_tag               = optional(string, null)
      virtual_network_subnet_id = optional(string, null)
      headers = optional(object({
        x_azure_fdid      = optional(string, null)
        x_fd_health_probe = optional(string, null)
        x_forwarded_for   = optional(string, null)
        x_forwarded_host  = optional(string, null)
      }), null)
    })), [])
    cors = optional(object({
      allowed_origins     = optional(list(string), null)
      support_credentials = optional(bool, false)
    }), null)
  })
  default = {}
}

variable "site_config_application_stack" {
  description = "Application stack configuration"
  type = object({
    docker_image           = optional(string, null)
    docker_image_tag       = optional(string, null)
    dotnet_version         = optional(string, null)
    java_version           = optional(string, null)
    node_version           = optional(string, null)
    php_version            = optional(string, null)
    python_version         = optional(string, null)
    ruby_version           = optional(string, null)
    go_version             = optional(string, null)
    current_stack          = optional(string, null)
    java_container         = optional(string, null)
    java_container_version = optional(string, null)
  })
  default = null
}

# Identity
variable "identity_type" {
  description = "Type of Managed Identity (SystemAssigned, UserAssigned, SystemAssigned, UserAssigned)"
  type        = string
  default     = null
}

variable "identity_ids" {
  description = "List of User Assigned Identity IDs (required if identity_type includes UserAssigned)"
  type        = list(string)
  default     = null
}

# Auth Settings
variable "auth_settings" {
  description = "Authentication settings"
  type = object({
    enabled                        = bool
    additional_login_parameters    = optional(map(string), null)
    allowed_external_redirect_urls = optional(list(string), null)
    default_provider               = optional(string, null)
    issuer                         = optional(string, null)
    runtime_version                = optional(string, null)
    token_refresh_extension_hours  = optional(number, null)
    token_store_enabled            = optional(bool, false)
    unauthenticated_client_action  = optional(string, null)
    active_directory = optional(object({
      client_id                  = string
      client_secret              = optional(string, null)
      client_secret_setting_name = optional(string, null)
      allowed_audiences          = optional(list(string), null)
    }), null)
    facebook = optional(object({
      app_id                  = string
      app_secret              = optional(string, null)
      app_secret_setting_name = optional(string, null)
      oauth_scopes            = optional(list(string), null)
    }), null)
    google = optional(object({
      client_id                  = string
      client_secret              = optional(string, null)
      client_secret_setting_name = optional(string, null)
      oauth_scopes               = optional(list(string), null)
    }), null)
    microsoft = optional(object({
      client_id                  = string
      client_secret              = optional(string, null)
      client_secret_setting_name = optional(string, null)
      oauth_scopes               = optional(list(string), null)
    }), null)
    twitter = optional(object({
      consumer_key                 = string
      consumer_secret              = optional(string, null)
      consumer_secret_setting_name = optional(string, null)
    }), null)
  })
  default = null
}

# Backup
variable "backup" {
  description = "Backup configuration"
  type = object({
    name                = string
    storage_account_url = string
    enabled             = optional(bool, true)
    schedule = object({
      frequency_interval       = number
      frequency_unit           = string
      keep_at_least_one_backup = optional(bool, false)
      retention_period_days    = optional(number, 30)
      start_time               = optional(string, null)
    })
  })
  default = null
}

# Storage Account Mounts
variable "storage_accounts" {
  description = "List of storage account mounts"
  type = list(object({
    name         = string
    type         = string # AzureBlob, AzureFiles
    account_name = string
    share_name   = string
    access_key   = optional(string, null)
    mount_path   = optional(string, null)
  }))
  default = []
}

# Deployment Slots
variable "deployment_slots" {
  description = "List of deployment slots to create for the App Service"
  type = list(object({
    name                               = string
    https_only                         = optional(bool)
    client_certificate_enabled         = optional(bool)
    client_certificate_mode            = optional(string)
    client_certificate_exclusion_paths = optional(list(string))
    enabled                            = optional(bool, true)
    public_network_access_enabled      = optional(bool)
    app_settings                       = optional(map(string), {})
    connection_strings = optional(list(object({
      name  = string
      type  = string
      value = string
    })), [])
    site_config = optional(object({
      always_on               = optional(bool)
      health_check_path       = optional(string)
      http2_enabled           = optional(bool)
      minimum_tls_version     = optional(string)
      scm_minimum_tls_version = optional(string)
      websockets_enabled      = optional(bool)
      windows_fx_version      = optional(string)
    }), {})
    site_config_application_stack = optional(object({
      docker_image           = optional(string)
      docker_image_tag       = optional(string)
      dotnet_version         = optional(string)
      java_version           = optional(string)
      node_version           = optional(string)
      php_version            = optional(string)
      python_version         = optional(string)
      ruby_version           = optional(string)
      go_version             = optional(string)
      current_stack          = optional(string)
      java_container         = optional(string)
      java_container_version = optional(string)
    }), null)
    identity_type = optional(string)
    identity_ids  = optional(list(string))
    auth_settings = optional(any)
    storage_accounts = optional(list(object({
      name         = string
      type         = string
      account_name = string
      share_name   = string
      access_key   = optional(string)
      mount_path   = optional(string)
    })), [])
    tags = optional(map(string), {})
  }))
  default = []
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
