# Create Deployment Slots for Linux App Service
resource "azurerm_linux_web_app_slot" "app_service_slots_linux" {
  for_each = var.os_type == "Linux" && length(var.deployment_slots) > 0 ? { for slot in var.deployment_slots : slot.name => slot } : {}

  name           = each.value.name
  app_service_id = azurerm_linux_web_app.app_service_linux[0].id

  https_only                         = lookup(each.value, "https_only", var.https_only)
  client_certificate_enabled         = lookup(each.value, "client_certificate_enabled", var.client_certificate_enabled)
  client_certificate_mode            = lookup(each.value, "client_certificate_mode", var.client_certificate_mode)
  client_certificate_exclusion_paths = lookup(each.value, "client_certificate_exclusion_paths", null) != null ? join(",", lookup(each.value, "client_certificate_exclusion_paths", [])) : (var.client_certificate_exclusion_paths != null ? join(",", var.client_certificate_exclusion_paths) : null)

  enabled                       = lookup(each.value, "enabled", true)
  public_network_access_enabled = lookup(each.value, "public_network_access_enabled", var.public_network_access_enabled)

  # App Settings - Merge slot-specific with parent app settings
  app_settings = merge(
    var.app_settings,
    lookup(each.value, "app_settings", {})
  )

  # Connection Strings - Merge slot-specific with parent connection strings
  dynamic "connection_string" {
    for_each = concat(var.connection_strings, lookup(each.value, "connection_strings", []))
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  # Site Config - Use slot-specific or fallback to parent
  site_config {
    always_on               = lookup(lookup(each.value, "site_config", {}), "always_on", lookup(var.site_config, "always_on", true))
    health_check_path       = lookup(lookup(each.value, "site_config", {}), "health_check_path", lookup(var.site_config, "health_check_path", null))
    http2_enabled           = lookup(lookup(each.value, "site_config", {}), "http2_enabled", lookup(var.site_config, "http2_enabled", false))
    minimum_tls_version     = lookup(lookup(each.value, "site_config", {}), "minimum_tls_version", lookup(var.site_config, "minimum_tls_version", "1.2"))
    scm_minimum_tls_version = lookup(lookup(each.value, "site_config", {}), "scm_minimum_tls_version", lookup(var.site_config, "scm_minimum_tls_version", "1.2"))
    websockets_enabled      = lookup(lookup(each.value, "site_config", {}), "websockets_enabled", lookup(var.site_config, "websockets_enabled", false))

    dynamic "application_stack" {
      for_each = lookup(each.value, "site_config_application_stack", var.site_config_application_stack) != null ? [lookup(each.value, "site_config_application_stack", var.site_config_application_stack)] : []
      content {
        docker_image     = lookup(application_stack.value, "docker_image", null)
        docker_image_tag = lookup(application_stack.value, "docker_image_tag", null)
        dotnet_version   = lookup(application_stack.value, "dotnet_version", null)
        java_version     = lookup(application_stack.value, "java_version", null)
        node_version     = lookup(application_stack.value, "node_version", null)
        php_version      = lookup(application_stack.value, "php_version", null)
        python_version   = lookup(application_stack.value, "python_version", null)
        ruby_version     = lookup(application_stack.value, "ruby_version", null)
        go_version       = lookup(application_stack.value, "go_version", null)
      }
    }
  }

  # Identity
  dynamic "identity" {
    for_each = lookup(each.value, "identity_type", var.identity_type) != null ? [1] : []
    content {
      type         = lookup(each.value, "identity_type", var.identity_type)
      identity_ids = lookup(each.value, "identity_ids", var.identity_ids)
    }
  }

  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

# Create Deployment Slots for Windows App Service
resource "azurerm_windows_web_app_slot" "app_service_slots_windows" {
  for_each = var.os_type == "Windows" && length(var.deployment_slots) > 0 ? { for slot in var.deployment_slots : slot.name => slot } : {}

  name           = each.value.name
  app_service_id = azurerm_windows_web_app.app_service_windows[0].id

  https_only                         = lookup(each.value, "https_only", var.https_only)
  client_certificate_enabled         = lookup(each.value, "client_certificate_enabled", var.client_certificate_enabled)
  client_certificate_mode            = lookup(each.value, "client_certificate_mode", var.client_certificate_mode)
  client_certificate_exclusion_paths = lookup(each.value, "client_certificate_exclusion_paths", null) != null ? join(",", lookup(each.value, "client_certificate_exclusion_paths", [])) : (var.client_certificate_exclusion_paths != null ? join(",", var.client_certificate_exclusion_paths) : null)

  enabled                       = lookup(each.value, "enabled", true)
  public_network_access_enabled = lookup(each.value, "public_network_access_enabled", var.public_network_access_enabled)

  # App Settings
  app_settings = merge(
    var.app_settings,
    lookup(each.value, "app_settings", {})
  )

  # Connection Strings
  dynamic "connection_string" {
    for_each = concat(var.connection_strings, lookup(each.value, "connection_strings", []))
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  # Site Config
  site_config {
    always_on               = lookup(lookup(each.value, "site_config", {}), "always_on", lookup(var.site_config, "always_on", true))
    health_check_path       = lookup(lookup(each.value, "site_config", {}), "health_check_path", lookup(var.site_config, "health_check_path", null))
    http2_enabled           = lookup(lookup(each.value, "site_config", {}), "http2_enabled", lookup(var.site_config, "http2_enabled", false))
    minimum_tls_version     = lookup(lookup(each.value, "site_config", {}), "minimum_tls_version", lookup(var.site_config, "minimum_tls_version", "1.2"))
    scm_minimum_tls_version = lookup(lookup(each.value, "site_config", {}), "scm_minimum_tls_version", lookup(var.site_config, "scm_minimum_tls_version", "1.2"))
    websockets_enabled      = lookup(lookup(each.value, "site_config", {}), "websockets_enabled", lookup(var.site_config, "websockets_enabled", false))
    windows_fx_version      = lookup(lookup(each.value, "site_config", {}), "windows_fx_version", lookup(var.site_config, "windows_fx_version", null))

    dynamic "application_stack" {
      for_each = lookup(each.value, "site_config_application_stack", var.site_config_application_stack) != null ? [lookup(each.value, "site_config_application_stack", var.site_config_application_stack)] : []
      content {
        dotnet_version         = lookup(application_stack.value, "dotnet_version", null)
        java_version           = lookup(application_stack.value, "java_version", null)
        node_version           = lookup(application_stack.value, "node_version", null)
        php_version            = lookup(application_stack.value, "php_version", null)
        python_version         = lookup(application_stack.value, "python_version", null)
        current_stack          = lookup(application_stack.value, "current_stack", null)
        java_container         = lookup(application_stack.value, "java_container", null)
        java_container_version = lookup(application_stack.value, "java_container_version", null)
      }
    }
  }

  # Identity
  dynamic "identity" {
    for_each = lookup(each.value, "identity_type", var.identity_type) != null ? [1] : []
    content {
      type         = lookup(each.value, "identity_type", var.identity_type)
      identity_ids = lookup(each.value, "identity_ids", var.identity_ids)
    }
  }

  tags = merge(var.tags, lookup(each.value, "tags", {}))
}
