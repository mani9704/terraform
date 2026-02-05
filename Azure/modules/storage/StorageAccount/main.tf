# Create Resource Group (if not provided)
resource "azurerm_resource_group" "sa_rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create Storage Account
resource "azurerm_storage_account" "storage_account" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind
  
  # Access tier
  access_tier = var.access_tier
  
  # Enable/Disable features
  enable_https_traffic_only          = var.enable_https_traffic_only
  min_tls_version                    = var.min_tls_version
  allow_nested_items_to_be_public    = var.allow_nested_items_to_be_public
  shared_access_key_enabled          = var.shared_access_key_enabled
  public_network_access_enabled      = var.public_network_access_enabled
  default_to_oauth_authentication    = var.default_to_oauth_authentication
  
  # Cross Tenant Replication
  cross_tenant_replication_enabled = var.cross_tenant_replication_enabled
  
  # Custom Domain
  custom_domain {
    name          = var.custom_domain.name
    use_subdomain = lookup(var.custom_domain, "use_subdomain", null)
  } if var.custom_domain != null

  # Customer Managed Key (CMK)
  customer_managed_key {
    key_vault_key_id          = var.customer_managed_key.key_vault_key_id
    user_assigned_identity_id = lookup(var.customer_managed_key, "user_assigned_identity_id", null)
  } if var.customer_managed_key != null

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_ids
    }
  }

  # Blob Properties
  blob_properties {
    versioning_enabled       = lookup(var.blob_properties, "versioning_enabled", false)
    change_feed_enabled      = lookup(var.blob_properties, "change_feed_enabled", false)
    default_service_version  = lookup(var.blob_properties, "default_service_version", null)
    last_access_time_enabled = lookup(var.blob_properties, "last_access_time_enabled", false)
    
    # Delete Retention Policy
    delete_retention_policy {
      days = lookup(var.blob_properties.delete_retention_policy, "days", 7)
    } if lookup(var.blob_properties, "delete_retention_policy", null) != null
    
    # Container Delete Retention Policy
    container_delete_retention_policy {
      days = lookup(var.blob_properties.container_delete_retention_policy, "days", 7)
    } if lookup(var.blob_properties, "container_delete_retention_policy", null) != null
    
    # CORS Rules
    dynamic "cors_rule" {
      for_each = lookup(var.blob_properties, "cors_rules", [])
      content {
        allowed_headers    = cors_rule.value.allowed_headers
        allowed_methods    = cors_rule.value.allowed_methods
        allowed_origins    = cors_rule.value.allowed_origins
        exposed_headers    = lookup(cors_rule.value, "exposed_headers", [])
        max_age_in_seconds = lookup(cors_rule.value, "max_age_in_seconds", 0)
      }
    }
  } if var.blob_properties != null

  # Queue Properties
  queue_properties {
    hour_metrics {
      enabled               = lookup(var.queue_properties.hour_metrics, "enabled", true)
      include_apis          = lookup(var.queue_properties.hour_metrics, "include_apis", true)
      retention_policy_days = lookup(var.queue_properties.hour_metrics, "retention_policy_days", 7)
    } if lookup(var.queue_properties, "hour_metrics", null) != null
    
    minute_metrics {
      enabled               = lookup(var.queue_properties.minute_metrics, "enabled", false)
      include_apis          = lookup(var.queue_properties.minute_metrics, "include_apis", true)
      retention_policy_days = lookup(var.queue_properties.minute_metrics, "retention_policy_days", 7)
    } if lookup(var.queue_properties, "minute_metrics", null) != null
    
    logging {
      delete                = lookup(var.queue_properties.logging, "delete", false)
      read                  = lookup(var.queue_properties.logging, "read", false)
      version               = lookup(var.queue_properties.logging, "version", "1.0")
      write                 = lookup(var.queue_properties.logging, "write", false)
      retention_policy_days = lookup(var.queue_properties.logging, "retention_policy_days", 7)
    } if lookup(var.queue_properties, "logging", null) != null
  } if var.queue_properties != null

  # Static Website
  static_website {
    index_document     = var.static_website.index_document
    error_404_document = lookup(var.static_website, "error_404_document", null)
  } if var.static_website != null

  # Network Rules
  dynamic "network_rules" {
    for_each = var.network_rules != null ? [var.network_rules] : []
    content {
      default_action             = network_rules.value.default_action
      bypass                     = lookup(network_rules.value, "bypass", ["AzureServices"])
      ip_rules                   = lookup(network_rules.value, "ip_rules", [])
      virtual_network_subnet_ids = lookup(network_rules.value, "virtual_network_subnet_ids", [])
    }
  }

  # Routing
  dynamic "routing" {
    for_each = var.routing != null ? [var.routing] : []
    content {
      publish_internet_endpoints  = lookup(routing.value, "publish_internet_endpoints", false)
      publish_microsoft_endpoints = lookup(routing.value, "publish_microsoft_endpoints", false)
      choice                      = lookup(routing.value, "choice", "MicrosoftRouting")
    }
  }

  tags = var.tags
}

# Create Storage Containers
resource "azurerm_storage_container" "containers" {
  for_each = { for container in var.containers : container.name => container }

  name                  = each.value.name
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = lookup(each.value, "container_access_type", "private")
  
  metadata = lookup(each.value, "metadata", null)

  depends_on = [azurerm_storage_account.storage_account]
}

# Create File Shares (for App Service Storage Mounts)
resource "azurerm_storage_share" "file_shares" {
  for_each = { for share in var.file_shares : share.name => share }

  name                 = each.value.name
  storage_account_name = azurerm_storage_account.storage_account.name
  quota                = lookup(each.value, "quota", 5120) # Default 5GB
  
  access_tier = lookup(each.value, "access_tier", "TransactionOptimized")
  enabled_protocol = lookup(each.value, "enabled_protocol", "SMB")
  metadata = lookup(each.value, "metadata", null)

  depends_on = [azurerm_storage_account.storage_account]
}

# Create Storage Tables
resource "azurerm_storage_table" "tables" {
  for_each = { for table in var.tables : table.name => table }

  name                 = each.value.name
  storage_account_name = azurerm_storage_account.storage_account.name

  depends_on = [azurerm_storage_account.storage_account]
}

# Create Storage Queues
resource "azurerm_storage_queue" "queues" {
  for_each = { for queue in var.queues : queue.name => queue }

  name                 = each.value.name
  storage_account_name = azurerm_storage_account.storage_account.name
  
  metadata = lookup(each.value, "metadata", null)

  depends_on = [azurerm_storage_account.storage_account]
}
