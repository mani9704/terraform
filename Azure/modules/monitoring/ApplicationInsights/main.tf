# Create Resource Group (if not provided)
resource "azurerm_resource_group" "appinsights_rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create Application Insights
resource "azurerm_application_insights" "appinsights" {
  name                                  = var.application_insights_name
  location                              = var.location
  resource_group_name                   = var.resource_group_name
  application_type                      = var.application_type
  daily_data_cap_in_gb                  = var.daily_data_cap_in_gb
  daily_data_cap_notifications_disabled = var.daily_data_cap_notifications_disabled
  retention_in_days                     = var.retention_in_days
  sampling_percentage                   = var.sampling_percentage
  disable_ip_masking                    = var.disable_ip_masking
  workspace_id                          = var.log_analytics_workspace_id
  local_authentication_disabled         = var.local_authentication_disabled
  internet_ingestion_enabled            = var.internet_ingestion_enabled
  internet_query_enabled                = var.internet_query_enabled
  force_customer_storage_for_profiler   = var.force_customer_storage_for_profiler

  tags = var.tags
}

# Create Application Insights Web Tests (optional)
resource "azurerm_application_insights_web_test" "web_tests" {
  for_each = { for test in var.web_tests : test.name => test }

  name                    = each.value.name
  location                = var.location
  resource_group_name     = var.resource_group_name
  application_insights_id = azurerm_application_insights.appinsights.id
  kind                    = each.value.kind
  frequency               = lookup(each.value, "frequency", 300)
  timeout                 = lookup(each.value, "timeout", 60)
  enabled                 = lookup(each.value, "enabled", true)
  geo_locations           = lookup(each.value, "geo_locations", ["us-ca-sjc-azr"])
  retry_enabled           = lookup(each.value, "retry_enabled", false)
  description             = lookup(each.value, "description", null)

  configuration = each.value.configuration

  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

# Create Application Insights API Keys (optional)
resource "azurerm_application_insights_api_key" "api_keys" {
  for_each = { for key in var.api_keys : key.name => key }

  name                    = each.value.name
  application_insights_id = azurerm_application_insights.appinsights.id
  read_permissions        = lookup(each.value, "read_permissions", [])
  write_permissions       = lookup(each.value, "write_permissions", [])
}

# Create Application Insights Smart Detection Rules (optional)
resource "azurerm_application_insights_smart_detection_rule" "smart_detection_rules" {
  for_each = { for rule in var.smart_detection_rules : rule.name => rule }

  name                               = each.value.name
  application_insights_id            = azurerm_application_insights.appinsights.id
  enabled                            = lookup(each.value, "enabled", true)
  send_emails_to_subscription_owners = lookup(each.value, "send_emails_to_subscription_owners", false)

  additional_email_recipients = lookup(each.value, "additional_email_recipients", [])
}
