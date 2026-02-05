# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}

output "resource_group_id" {
  description = "ID of the resource group (if created)"
  value       = var.create_resource_group ? azurerm_resource_group.sa_rg[0].id : null
}

# Storage Account Outputs
output "storage_account_id" {
  description = "ID of the Storage Account"
  value       = azurerm_storage_account.storage_account.id
}

output "storage_account_name" {
  description = "Name of the Storage Account"
  value       = azurerm_storage_account.storage_account.name
}

output "storage_account_primary_location" {
  description = "The primary location of the Storage Account"
  value       = azurerm_storage_account.storage_account.primary_location
}

output "storage_account_secondary_location" {
  description = "The secondary location of the Storage Account"
  value       = azurerm_storage_account.storage_account.secondary_location
}

output "primary_access_key" {
  description = "The primary access key for the Storage Account"
  value       = azurerm_storage_account.storage_account.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "The secondary access key for the Storage Account"
  value       = azurerm_storage_account.storage_account.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "The connection string associated with the primary location"
  value       = azurerm_storage_account.storage_account.primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "The connection string associated with the secondary location"
  value       = azurerm_storage_account.storage_account.secondary_connection_string
  sensitive   = true
}

output "primary_blob_endpoint" {
  description = "The endpoint URL for blob storage in the primary location"
  value       = azurerm_storage_account.storage_account.primary_blob_endpoint
}

output "primary_blob_host" {
  description = "The hostname with port if applicable for blob storage in the primary location"
  value       = azurerm_storage_account.storage_account.primary_blob_host
}

output "primary_file_endpoint" {
  description = "The endpoint URL for file storage in the primary location"
  value       = azurerm_storage_account.storage_account.primary_file_endpoint
}

output "primary_file_host" {
  description = "The hostname with port if applicable for file storage in the primary location"
  value       = azurerm_storage_account.storage_account.primary_file_host
}

output "primary_queue_endpoint" {
  description = "The endpoint URL for queue storage in the primary location"
  value       = azurerm_storage_account.storage_account.primary_queue_endpoint
}

output "primary_table_endpoint" {
  description = "The endpoint URL for table storage in the primary location"
  value       = azurerm_storage_account.storage_account.primary_table_endpoint
}

# Container Outputs
output "container_ids" {
  description = "Map of container names to their IDs"
  value = {
    for k, v in azurerm_storage_container.containers : k => v.id
  }
}

# File Share Outputs (for App Service Storage Mounts)
output "file_share_ids" {
  description = "Map of file share names to their IDs"
  value = {
    for k, v in azurerm_storage_share.file_shares : k => v.id
  }
}

output "file_share_urls" {
  description = "Map of file share names to their URLs (for App Service storage mounts)"
  value = {
    for k, v in azurerm_storage_share.file_shares : k => "\\\\${azurerm_storage_account.storage_account.name}.file.core.windows.net\\${v.name}"
  }
}

output "file_share_names" {
  description = "Map of file share names"
  value = {
    for k, v in azurerm_storage_share.file_shares : k => v.name
  }
}

# Table Outputs
output "table_ids" {
  description = "Map of table names to their IDs"
  value = {
    for k, v in azurerm_storage_table.tables : k => v.id
  }
}

# Queue Outputs
output "queue_ids" {
  description = "Map of queue names to their IDs"
  value = {
    for k, v in azurerm_storage_queue.queues : k => v.id
  }
}
