# Create Resource Group (if not provided)
resource "azurerm_resource_group" "law_rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = var.log_analytics_workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  retention_in_days   = var.retention_in_days
  
  # Optional: Allow resource only logs
  allow_resource_only_permissions = var.allow_resource_only_permissions
  
  # Optional: Daily quota in GB
  daily_quota_gb = var.daily_quota_gb
  
  # Optional: Internet ingestion enabled
  internet_ingestion_enabled = var.internet_ingestion_enabled
  
  # Optional: Internet query enabled
  internet_query_enabled = var.internet_query_enabled
  
  # Optional: Local authentication disabled
  local_authentication_disabled = var.local_authentication_disabled
  
  # Optional: Reservation capacity in GB per day (reservation_capcity_in_gb_per_day)
  reservation_capacity_in_gb_per_day = var.reservation_capacity_in_gb_per_day

  tags = var.tags
}

# Create Log Analytics Workspace Solutions (optional)
resource "azurerm_log_analytics_solution" "law_solutions" {
  for_each = { for solution in var.solutions : solution.solution_name => solution }

  solution_name         = each.value.solution_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.law.id
  workspace_name        = azurerm_log_analytics_workspace.law.name

  plan {
    publisher = each.value.publisher
    product   = each.value.product
  }

  tags = merge(var.tags, lookup(each.value, "tags", {}))
}
