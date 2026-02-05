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

# Storage Account Variables
variable "storage_account_name" {
  description = "Name of the Storage Account (must be globally unique, lowercase alphanumeric and hyphens only)"
  type        = string
}

variable "account_tier" {
  description = "Defines the Tier to use for this storage account. Valid options are Standard and Premium"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS"
  type        = string
  default     = "LRS"
}

variable "account_kind" {
  description = "The kind of storage account. Valid options are Storage, StorageV2, BlobStorage, FileStorage, BlockBlobStorage"
  type        = string
  default     = "StorageV2"
}

variable "access_tier" {
  description = "Defines the access tier for BlobStorage, FileStorage and StorageV2 accounts. Valid options are Hot and Cool"
  type        = string
  default     = "Hot"
}

variable "enable_https_traffic_only" {
  description = "Boolean flag which forces HTTPS if enabled"
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "The minimum supported TLS version for the storage account. Possible values are TLS1_0, TLS1_1, and TLS1_2"
  type        = string
  default     = "TLS1_2"
}

variable "allow_nested_items_to_be_public" {
  description = "Allow or disallow nested items within this Account to opt into being public"
  type        = bool
  default     = false
}

variable "shared_access_key_enabled" {
  description = "Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Whether the public network access is enabled"
  type        = bool
  default     = true
}

variable "default_to_oauth_authentication" {
  description = "Default to Azure Active Directory authorization in the Azure portal when accessing the Storage Account"
  type        = bool
  default     = false
}

variable "cross_tenant_replication_enabled" {
  description = "Should cross Tenant replication be enabled?"
  type        = bool
  default     = true
}

variable "custom_domain" {
  description = "Custom domain configuration"
  type = object({
    name          = string
    use_subdomain = optional(bool, null)
  })
  default = null
}

variable "customer_managed_key" {
  description = "Customer Managed Key configuration"
  type = object({
    key_vault_key_id          = string
    user_assigned_identity_id = optional(string, null)
  })
  default = null
}

variable "identity_type" {
  description = "The type of Managed Identity which should be assigned to the Storage Account. Possible values are SystemAssigned, UserAssigned, SystemAssigned,UserAssigned"
  type        = string
  default     = null
}

variable "identity_ids" {
  description = "A list of User Assigned Managed Identity IDs to be assigned to the Storage Account"
  type        = list(string)
  default     = null
}

variable "blob_properties" {
  description = "Blob properties configuration"
  type = object({
    versioning_enabled       = optional(bool, false)
    change_feed_enabled      = optional(bool, false)
    default_service_version  = optional(string, null)
    last_access_time_enabled = optional(bool, false)
    delete_retention_policy = optional(object({
      days = number
    }), null)
    container_delete_retention_policy = optional(object({
      days = number
    }), null)
    cors_rules = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = optional(list(string), [])
      max_age_in_seconds = optional(number, 0)
    })), [])
  })
  default = null
}

variable "queue_properties" {
  description = "Queue properties configuration"
  type = object({
    hour_metrics = optional(object({
      enabled               = bool
      include_apis          = optional(bool, true)
      retention_policy_days = optional(number, 7)
    }), null)
    minute_metrics = optional(object({
      enabled               = bool
      include_apis          = optional(bool, true)
      retention_policy_days = optional(number, 7)
    }), null)
    logging = optional(object({
      delete                = bool
      read                  = bool
      version               = optional(string, "1.0")
      write                 = bool
      retention_policy_days = optional(number, 7)
    }), null)
  })
  default = null
}

variable "static_website" {
  description = "Static website configuration"
  type = object({
    index_document     = string
    error_404_document = optional(string, null)
  })
  default = null
}

variable "network_rules" {
  description = "Network rules for restricting access"
  type = object({
    default_action             = string # Allow or Deny
    bypass                     = optional(list(string), ["AzureServices"])
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = null
}

variable "routing" {
  description = "Routing configuration"
  type = object({
    publish_internet_endpoints  = optional(bool, false)
    publish_microsoft_endpoints = optional(bool, false)
    choice                      = optional(string, "MicrosoftRouting") # MicrosoftRouting or InternetRouting
  })
  default = null
}

# Containers
variable "containers" {
  description = "List of storage containers to create"
  type = list(object({
    name                 = string
    container_access_type = optional(string, "private") # private, blob, container
    metadata             = optional(map(string), null)
  }))
  default = []
}

# File Shares (for App Service Storage Mounts)
variable "file_shares" {
  description = "List of file shares to create (used for App Service storage mounts)"
  type = list(object({
    name          = string
    quota         = optional(number, 5120) # Size in GB (default 5GB, max 102400GB)
    access_tier   = optional(string, "TransactionOptimized") # TransactionOptimized, Hot, Cool
    enabled_protocol = optional(string, "SMB") # SMB or NFS
    metadata      = optional(map(string), null)
  }))
  default = []
}

# Tables
variable "tables" {
  description = "List of storage tables to create"
  type = list(object({
    name = string
  }))
  default = []
}

# Queues
variable "queues" {
  description = "List of storage queues to create"
  type = list(object({
    name     = string
    metadata = optional(map(string), null)
  }))
  default = []
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
