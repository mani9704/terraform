# Create Resource Group (if not provided)
resource "azurerm_resource_group" "tm_rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create Traffic Manager Profile
resource "azurerm_traffic_manager_profile" "tm_profile" {
  name                   = var.traffic_manager_name
  resource_group_name    = var.resource_group_name
  traffic_routing_method = var.traffic_routing_method

  dns_config {
    relative_name = var.relative_dns_name
    ttl           = var.ttl
  }

  monitor_config {
    protocol                     = var.monitor_config.protocol
    port                         = var.monitor_config.port
    path                         = var.monitor_config.path
    interval_in_seconds          = var.monitor_config.interval_in_seconds
    timeout_in_seconds           = var.monitor_config.timeout_in_seconds
    tolerated_number_of_failures = var.monitor_config.tolerated_number_of_failures
    expected_status_code_ranges  = var.monitor_config.expected_status_code_ranges

    dynamic "custom_header" {
      for_each = var.monitor_config.custom_headers
      content {
        name  = custom_header.value.name
        value = custom_header.value.value
      }
    }
  }

  tags = var.tags
}

# Create Traffic Manager Endpoints
resource "azurerm_traffic_manager_azure_endpoint" "azure_endpoints" {
  for_each = {
    for endpoint in var.endpoints : endpoint.name => endpoint
    if endpoint.type == "azure"
  }

  name               = each.value.name
  profile_id         = azurerm_traffic_manager_profile.tm_profile.id
  target_resource_id = each.value.target_resource_id
  weight             = lookup(each.value, "weight", 1)
  priority           = lookup(each.value, "priority", null)
  enabled            = lookup(each.value, "enabled", true)

  dynamic "custom_header" {
    for_each = lookup(each.value, "custom_headers", [])
    content {
      name  = custom_header.value.name
      value = custom_header.value.value
    }
  }

  dynamic "subnet" {
    for_each = lookup(each.value, "subnets", [])
    content {
      first = subnet.value.first
      last  = lookup(subnet.value, "last", null)
      scope = lookup(subnet.value, "scope", null)
    }
  }
}

resource "azurerm_traffic_manager_external_endpoint" "external_endpoints" {
  for_each = {
    for endpoint in var.endpoints : endpoint.name => endpoint
    if endpoint.type == "external"
  }

  name       = each.value.name
  profile_id = azurerm_traffic_manager_profile.tm_profile.id
  target     = each.value.target
  weight     = lookup(each.value, "weight", 1)
  priority   = lookup(each.value, "priority", null)
  enabled    = lookup(each.value, "enabled", true)

  dynamic "custom_header" {
    for_each = lookup(each.value, "custom_headers", [])
    content {
      name  = custom_header.value.name
      value = custom_header.value.value
    }
  }

  dynamic "subnet" {
    for_each = lookup(each.value, "subnets", [])
    content {
      first = subnet.value.first
      last  = lookup(subnet.value, "last", null)
      scope = lookup(subnet.value, "scope", null)
    }
  }
}

resource "azurerm_traffic_manager_nested_endpoint" "nested_endpoints" {
  for_each = {
    for endpoint in var.endpoints : endpoint.name => endpoint
    if endpoint.type == "nested"
  }

  name                                  = each.value.name
  profile_id                            = azurerm_traffic_manager_profile.tm_profile.id
  target_resource_id                    = each.value.target_resource_id
  weight                                = lookup(each.value, "weight", 1)
  priority                              = lookup(each.value, "priority", null)
  enabled                               = lookup(each.value, "enabled", true)
  minimum_child_endpoints               = lookup(each.value, "minimum_child_endpoints", 1)
  minimum_required_child_endpoints_ipv4 = lookup(each.value, "minimum_required_child_endpoints_ipv4", null)
  minimum_required_child_endpoints_ipv6 = lookup(each.value, "minimum_required_child_endpoints_ipv6", null)

  dynamic "custom_header" {
    for_each = lookup(each.value, "custom_headers", [])
    content {
      name  = custom_header.value.name
      value = custom_header.value.value
    }
  }

  dynamic "subnet" {
    for_each = lookup(each.value, "subnets", [])
    content {
      first = subnet.value.first
      last  = lookup(subnet.value, "last", null)
      scope = lookup(subnet.value, "scope", null)
    }
  }
}
