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
  enable_https_traffic_only       = var.enable_https_traffic_only
  min_tls_version                 = var.min_tls_version
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  shared_access_key_enabled       = var.shared_access_key_enabled
  public_network_access_enabled   = var.public_network_access_enabled
  default_to_oauth_authentication = var.default_to_oauth_authentication

  # Cross Tenant Replication
  cross_tenant_replication_enabled = var.cross_tenant_replication_enabled

  # Custom Domain
  dynamic "custom_domain" {
    for_each = var.custom_domain != null ? [var.custom_domain] : []
    content {
      name          = custom_domain.value.name
      use_subdomain = lookup(custom_domain.value, "use_subdomain", null)
    }
  }

  # Customer Managed Key (CMK)
  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key != null ? [var.customer_managed_key] : []
    content {
      key_vault_key_id          = customer_managed_key.value.key_vault_key_id
      user_assigned_identity_id = lookup(customer_managed_key.value, "user_assigned_identity_id", null)
    }
  }

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_ids
    }
  }

  # Blob Properties
  dynamic "blob_properties" {
    for_each = var.blob_properties != null ? [var.blob_properties] : []
    content {
      versioning_enabled       = lookup(blob_properties.value, "versioning_enabled", false)
      change_feed_enabled      = lookup(blob_properties.value, "change_feed_enabled", false)
      default_service_version  = lookup(blob_properties.value, "default_service_version", null)
      last_access_time_enabled = lookup(blob_properties.value, "last_access_time_enabled", false)

      # Delete Retention Policy
      dynamic "delete_retention_policy" {
        for_each = lookup(blob_properties.value, "delete_retention_policy", null) != null ? [blob_properties.value.delete_retention_policy] : []
        content {
          days = lookup(delete_retention_policy.value, "days", 7)
        }
      }

      # Container Delete Retention Policy
      dynamic "container_delete_retention_policy" {
        for_each = lookup(blob_properties.value, "container_delete_retention_policy", null) != null ? [blob_properties.value.container_delete_retention_policy] : []
        content {
          days = lookup(container_delete_retention_policy.value, "days", 7)
        }
      }

      # CORS Rules
      dynamic "cors_rule" {
        for_each = lookup(blob_properties.value, "cors_rules", [])
        content {
          allowed_headers    = cors_rule.value.allowed_headers
          allowed_methods    = cors_rule.value.allowed_methods
          allowed_origins    = cors_rule.value.allowed_origins
          exposed_headers    = lookup(cors_rule.value, "exposed_headers", [])
          max_age_in_seconds = lookup(cors_rule.value, "max_age_in_seconds", 0)
        }
      }
    }
  }

  # Queue Properties
  dynamic "queue_properties" {
    for_each = var.queue_properties != null ? [var.queue_properties] : []
    content {
      dynamic "hour_metrics" {
        for_each = lookup(queue_properties.value, "hour_metrics", null) != null ? [queue_properties.value.hour_metrics] : []
        content {
          version               = lookup(hour_metrics.value, "version", "1.0")
          enabled               = hour_metrics.value.enabled
          include_apis          = lookup(hour_metrics.value, "include_apis", true)
          retention_policy_days = lookup(hour_metrics.value, "retention_policy_days", 7)
        }
      }

      dynamic "minute_metrics" {
        for_each = lookup(queue_properties.value, "minute_metrics", null) != null ? [queue_properties.value.minute_metrics] : []
        content {
          version               = lookup(minute_metrics.value, "version", "1.0")
          enabled               = minute_metrics.value.enabled
          include_apis          = lookup(minute_metrics.value, "include_apis", true)
          retention_policy_days = lookup(minute_metrics.value, "retention_policy_days", 7)
        }
      }

      dynamic "logging" {
        for_each = lookup(queue_properties.value, "logging", null) != null ? [queue_properties.value.logging] : []
        content {
          delete                = logging.value.delete
          read                  = logging.value.read
          version               = lookup(logging.value, "version", "1.0")
          write                 = logging.value.write
          retention_policy_days = lookup(logging.value, "retention_policy_days", 7)
        }
      }
    }
  }

  # Static Website
  dynamic "static_website" {
    for_each = var.static_website != null ? [var.static_website] : []
    content {
      index_document     = static_website.value.index_document
      error_404_document = lookup(static_website.value, "error_404_document", null)
    }
  }

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

  access_tier      = lookup(each.value, "access_tier", "TransactionOptimized")
  enabled_protocol = lookup(each.value, "enabled_protocol", "SMB")
  metadata         = lookup(each.value, "metadata", null)

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
