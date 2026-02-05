# Create Resource Group (if not provided)
resource "azurerm_resource_group" "app_service_rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create App Service Plan
resource "azurerm_service_plan" "app_service_plan" {
  count = var.create_app_service_plan ? 1 : 0

  name                = var.app_service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = var.app_service_plan_os_type
  sku_name            = var.app_service_plan_sku_name

  zone_balancing_enabled = lookup(var.app_service_plan_config, "zone_balancing_enabled", false)
  per_site_scaling_enabled = lookup(var.app_service_plan_config, "per_site_scaling_enabled", false)
  reserved                = var.app_service_plan_os_type == "Linux" ? true : false

  tags = var.tags
}

# Create App Service
resource "azurerm_linux_web_app" "app_service_linux" {
  count = var.os_type == "Linux" ? 1 : 0

  name                = var.app_service_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = var.app_service_plan_id != null ? var.app_service_plan_id : azurerm_service_plan.app_service_plan[0].id

  https_only                  = var.https_only
  client_certificate_enabled  = var.client_certificate_enabled
  client_certificate_mode     = var.client_certificate_mode
  client_certificate_exclusion_paths = var.client_certificate_exclusion_paths

  enabled     = var.enabled
  public_network_access_enabled = var.public_network_access_enabled

  # App Settings
  app_settings = var.app_settings

  # Connection Strings
  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  # Site Config
  site_config {
    always_on                                     = lookup(var.site_config, "always_on", true)
    api_definition_url                            = lookup(var.site_config, "api_definition_url", null)
    api_management_api_id                         = lookup(var.site_config, "api_management_api_id", null)
    app_command_line                              = lookup(var.site_config, "app_command_line", null)
    application_insights_connection_string        = lookup(var.site_config, "application_insights_connection_string", null)
    application_insights_key                      = lookup(var.site_config, "application_insights_key", null)
    application_stack {
      docker_image        = lookup(var.site_config_application_stack, "docker_image", null)
      docker_image_tag    = lookup(var.site_config_application_stack, "docker_image_tag", null)
      dotnet_version      = lookup(var.site_config_application_stack, "dotnet_version", null)
      java_version        = lookup(var.site_config_application_stack, "java_version", null)
      node_version        = lookup(var.site_config_application_stack, "node_version", null)
      php_version         = lookup(var.site_config_application_stack, "php_version", null)
      python_version      = lookup(var.site_config_application_stack, "python_version", null)
      ruby_version        = lookup(var.site_config_application_stack, "ruby_version", null)
      use_custom_runtime  = lookup(var.site_config_application_stack, "use_custom_runtime", null)
      go_version          = lookup(var.site_config_application_stack, "go_version", null)
    }
    auto_heal_enabled                             = lookup(var.site_config, "auto_heal_enabled", false)
    container_registry_managed_identity_client_id = lookup(var.site_config, "container_registry_managed_identity_client_id", null)
    container_registry_use_managed_identity       = lookup(var.site_config, "container_registry_use_managed_identity", false)
    default_documents                             = lookup(var.site_config, "default_documents", null)
    ftps_state                                   = lookup(var.site_config, "ftps_state", "Disabled")
    health_check_path                             = lookup(var.site_config, "health_check_path", null)
    health_check_eviction_time_in_min             = lookup(var.site_config, "health_check_eviction_time_in_min", null)
    http2_enabled                                 = lookup(var.site_config, "http2_enabled", false)
    ip_restriction_default_action                = lookup(var.site_config, "ip_restriction_default_action", "Allow")
    load_balancing_mode                          = lookup(var.site_config, "load_balancing_mode", "LeastRequests")
    managed_pipeline_mode                        = lookup(var.site_config, "managed_pipeline_mode", null)
    minimum_tls_version                          = lookup(var.site_config, "minimum_tls_version", "1.2")
    pre_warmed_instance_count                    = lookup(var.site_config, "pre_warmed_instance_count", null)
    remote_debugging_enabled                     = lookup(var.site_config, "remote_debugging_enabled", false)
    remote_debugging_version                     = lookup(var.site_config, "remote_debugging_version", null)
    scm_minimum_tls_version                      = lookup(var.site_config, "scm_minimum_tls_version", "1.2")
    scm_use_main_ip_restriction                  = lookup(var.site_config, "scm_use_main_ip_restriction", false)
    use_32_bit_worker                            = lookup(var.site_config, "use_32_bit_worker", false)
    vnet_route_all_enabled                       = lookup(var.site_config, "vnet_route_all_enabled", false)
    websockets_enabled                           = lookup(var.site_config, "websockets_enabled", false)
    worker_count                                 = lookup(var.site_config, "worker_count", null)

    # IP Restrictions
    dynamic "ip_restriction" {
      for_each = lookup(var.site_config, "ip_restrictions", [])
      content {
        action                    = lookup(ip_restriction.value, "action", "Allow")
        ip_address                = lookup(ip_restriction.value, "ip_address", null)
        name                      = lookup(ip_restriction.value, "name", null)
        priority                  = lookup(ip_restriction.value, "priority", null)
        service_tag               = lookup(ip_restriction.value, "service_tag", null)
        virtual_network_subnet_id = lookup(ip_restriction.value, "virtual_network_subnet_id", null)
        dynamic "headers" {
          for_each = lookup(ip_restriction.value, "headers", null) != null ? [ip_restriction.value.headers] : []
          content {
            x_azure_fdid      = lookup(headers.value, "x_azure_fdid", null)
            x_fd_health_probe = lookup(headers.value, "x_fd_health_probe", null)
            x_forwarded_for   = lookup(headers.value, "x_forwarded_for", null)
            x_forwarded_host  = lookup(headers.value, "x_forwarded_host", null)
          }
        }
      }
    }

    # Scm IP Restrictions
    dynamic "scm_ip_restriction" {
      for_each = lookup(var.site_config, "scm_ip_restrictions", [])
      content {
        action                    = lookup(scm_ip_restriction.value, "action", "Allow")
        ip_address                = lookup(scm_ip_restriction.value, "ip_address", null)
        name                      = lookup(scm_ip_restriction.value, "name", null)
        priority                  = lookup(scm_ip_restriction.value, "priority", null)
        service_tag               = lookup(scm_ip_restriction.value, "service_tag", null)
        virtual_network_subnet_id = lookup(scm_ip_restriction.value, "virtual_network_subnet_id", null)
        dynamic "headers" {
          for_each = lookup(scm_ip_restriction.value, "headers", null) != null ? [scm_ip_restriction.value.headers] : []
          content {
            x_azure_fdid      = lookup(headers.value, "x_azure_fdid", null)
            x_fd_health_probe = lookup(headers.value, "x_fd_health_probe", null)
            x_forwarded_for   = lookup(headers.value, "x_forwarded_for", null)
            x_forwarded_host  = lookup(headers.value, "x_forwarded_host", null)
          }
        }
      }
    }

    # CORS
    dynamic "cors" {
      for_each = lookup(var.site_config, "cors", null) != null ? [var.site_config.cors] : []
      content {
        allowed_origins     = lookup(cors.value, "allowed_origins", null)
        support_credentials = lookup(cors.value, "support_credentials", false)
      }
    }
  }

  # Identity (Managed Identity)
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_ids
    }
  }

  # Auth Settings
  dynamic "auth_settings" {
    for_each = var.auth_settings != null ? [var.auth_settings] : []
    content {
      enabled                        = auth_settings.value.enabled
      additional_login_parameters    = lookup(auth_settings.value, "additional_login_parameters", null)
      allowed_external_redirect_urls = lookup(auth_settings.value, "allowed_external_redirect_urls", null)
      default_provider              = lookup(auth_settings.value, "default_provider", null)
      issuer                        = lookup(auth_settings.value, "issuer", null)
      runtime_version               = lookup(auth_settings.value, "runtime_version", null)
      token_refresh_extension_hours = lookup(auth_settings.value, "token_refresh_extension_hours", null)
      token_store_enabled           = lookup(auth_settings.value, "token_store_enabled", false)
      unauthenticated_client_action = lookup(auth_settings.value, "unauthenticated_client_action", null)

      dynamic "active_directory" {
        for_each = lookup(auth_settings.value, "active_directory", null) != null ? [auth_settings.value.active_directory] : []
        content {
          client_id                 = active_directory.value.client_id
          client_secret             = lookup(active_directory.value, "client_secret", null)
          client_secret_setting_name = lookup(active_directory.value, "client_secret_setting_name", null)
          allowed_audiences         = lookup(active_directory.value, "allowed_audiences", null)
        }
      }

      dynamic "facebook" {
        for_each = lookup(auth_settings.value, "facebook", null) != null ? [auth_settings.value.facebook] : []
        content {
          app_id       = facebook.value.app_id
          app_secret   = lookup(facebook.value, "app_secret", null)
          app_secret_setting_name = lookup(facebook.value, "app_secret_setting_name", null)
          oauth_scopes = lookup(facebook.value, "oauth_scopes", null)
        }
      }

      dynamic "google" {
        for_each = lookup(auth_settings.value, "google", null) != null ? [auth_settings.value.google] : []
        content {
          client_id                 = google.value.client_id
          client_secret             = lookup(google.value, "client_secret", null)
          client_secret_setting_name = lookup(google.value, "client_secret_setting_name", null)
          oauth_scopes              = lookup(google.value, "oauth_scopes", null)
        }
      }

      dynamic "microsoft" {
        for_each = lookup(auth_settings.value, "microsoft", null) != null ? [auth_settings.value.microsoft] : []
        content {
          client_id                 = microsoft.value.client_id
          client_secret             = lookup(microsoft.value, "client_secret", null)
          client_secret_setting_name = lookup(microsoft.value, "client_secret_setting_name", null)
          oauth_scopes              = lookup(microsoft.value, "oauth_scopes", null)
        }
      }

      dynamic "twitter" {
        for_each = lookup(auth_settings.value, "twitter", null) != null ? [auth_settings.value.twitter] : []
        content {
          consumer_key              = twitter.value.consumer_key
          consumer_secret           = lookup(twitter.value, "consumer_secret", null)
          consumer_secret_setting_name = lookup(twitter.value, "consumer_secret_setting_name", null)
        }
      }
    }
  }

  # Backup (Optional)
  dynamic "backup" {
    for_each = var.backup != null ? [var.backup] : []
    content {
      name                = backup.value.name
      storage_account_url = backup.value.storage_account_url
      enabled             = lookup(backup.value, "enabled", true)
      schedule {
        frequency_interval       = backup.value.schedule.frequency_interval
        frequency_unit           = backup.value.schedule.frequency_unit
        keep_at_least_one_backup = lookup(backup.value.schedule, "keep_at_least_one_backup", false)
        retention_period_days    = lookup(backup.value.schedule, "retention_period_days", 30)
        start_time               = lookup(backup.value.schedule, "start_time", null)
      }
    }
  }

  # Storage Account Mounts
  dynamic "storage_account" {
    for_each = var.storage_accounts
    content {
      name         = storage_account.value.name
      type         = storage_account.value.type
      account_name = storage_account.value.account_name
      share_name   = storage_account.value.share_name
      access_key   = lookup(storage_account.value, "access_key", null)
      mount_path   = lookup(storage_account.value, "mount_path", null)
    }
  }

  tags = var.tags
}

resource "azurerm_windows_web_app" "app_service_windows" {
  count = var.os_type == "Windows" ? 1 : 0

  name                = var.app_service_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = var.app_service_plan_id != null ? var.app_service_plan_id : azurerm_service_plan.app_service_plan[0].id

  https_only                  = var.https_only
  client_certificate_enabled  = var.client_certificate_enabled
  client_certificate_mode     = var.client_certificate_mode
  client_certificate_exclusion_paths = var.client_certificate_exclusion_paths

  enabled     = var.enabled
  public_network_access_enabled = var.public_network_access_enabled

  # App Settings
  app_settings = var.app_settings

  # Connection Strings
  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  # Site Config (similar structure for Windows)
  site_config {
    always_on                                     = lookup(var.site_config, "always_on", true)
    api_definition_url                            = lookup(var.site_config, "api_definition_url", null)
    api_management_api_id                         = lookup(var.site_config, "api_management_api_id", null)
    app_command_line                              = lookup(var.site_config, "app_command_line", null)
    application_insights_connection_string        = lookup(var.site_config, "application_insights_connection_string", null)
    application_insights_key                      = lookup(var.site_config, "application_insights_key", null)
    default_documents                             = lookup(var.site_config, "default_documents", null)
    ftps_state                                   = lookup(var.site_config, "ftps_state", "Disabled")
    health_check_path                             = lookup(var.site_config, "health_check_path", null)
    health_check_eviction_time_in_min             = lookup(var.site_config, "health_check_eviction_time_in_min", null)
    http2_enabled                                 = lookup(var.site_config, "http2_enabled", false)
    ip_restriction_default_action                = lookup(var.site_config, "ip_restriction_default_action", "Allow")
    load_balancing_mode                          = lookup(var.site_config, "load_balancing_mode", "LeastRequests")
    managed_pipeline_mode                        = lookup(var.site_config, "managed_pipeline_mode", null)
    minimum_tls_version                          = lookup(var.site_config, "minimum_tls_version", "1.2")
    pre_warmed_instance_count                    = lookup(var.site_config, "pre_warmed_instance_count", null)
    remote_debugging_enabled                     = lookup(var.site_config, "remote_debugging_enabled", false)
    remote_debugging_version                     = lookup(var.site_config, "remote_debugging_version", null)
    scm_minimum_tls_version                      = lookup(var.site_config, "scm_minimum_tls_version", "1.2")
    scm_use_main_ip_restriction                  = lookup(var.site_config, "scm_use_main_ip_restriction", false)
    use_32_bit_worker                            = lookup(var.site_config, "use_32_bit_worker", false)
    vnet_route_all_enabled                       = lookup(var.site_config, "vnet_route_all_enabled", false)
    websockets_enabled                           = lookup(var.site_config, "websockets_enabled", false)
    worker_count                                 = lookup(var.site_config, "worker_count", null)

    # Windows specific
    windows_fx_version                            = lookup(var.site_config, "windows_fx_version", null)
    use_managed_identity_for_storage             = lookup(var.site_config, "use_managed_identity_for_storage", null)

    # Application Stack for Windows
    dynamic "application_stack" {
      for_each = var.site_config_application_stack != null ? [var.site_config_application_stack] : []
      content {
        dotnet_version             = lookup(application_stack.value, "dotnet_version", null)
        java_version               = lookup(application_stack.value, "java_version", null)
        node_version               = lookup(application_stack.value, "node_version", null)
        php_version                = lookup(application_stack.value, "php_version", null)
        python_version             = lookup(application_stack.value, "python_version", null)
        current_stack              = lookup(application_stack.value, "current_stack", null)
        java_container             = lookup(application_stack.value, "java_container", null)
        java_container_version     = lookup(application_stack.value, "java_container_version", null)
      }
    }

    # IP Restrictions
    dynamic "ip_restriction" {
      for_each = lookup(var.site_config, "ip_restrictions", [])
      content {
        action                    = lookup(ip_restriction.value, "action", "Allow")
        ip_address                = lookup(ip_restriction.value, "ip_address", null)
        name                      = lookup(ip_restriction.value, "name", null)
        priority                  = lookup(ip_restriction.value, "priority", null)
        service_tag               = lookup(ip_restriction.value, "service_tag", null)
        virtual_network_subnet_id = lookup(ip_restriction.value, "virtual_network_subnet_id", null)
        dynamic "headers" {
          for_each = lookup(ip_restriction.value, "headers", null) != null ? [ip_restriction.value.headers] : []
          content {
            x_azure_fdid      = lookup(headers.value, "x_azure_fdid", null)
            x_fd_health_probe = lookup(headers.value, "x_fd_health_probe", null)
            x_forwarded_for   = lookup(headers.value, "x_forwarded_for", null)
            x_forwarded_host  = lookup(headers.value, "x_forwarded_host", null)
          }
        }
      }
    }

    # Scm IP Restrictions
    dynamic "scm_ip_restriction" {
      for_each = lookup(var.site_config, "scm_ip_restrictions", [])
      content {
        action                    = lookup(scm_ip_restriction.value, "action", "Allow")
        ip_address                = lookup(scm_ip_restriction.value, "ip_address", null)
        name                      = lookup(scm_ip_restriction.value, "name", null)
        priority                  = lookup(scm_ip_restriction.value, "priority", null)
        service_tag               = lookup(scm_ip_restriction.value, "service_tag", null)
        virtual_network_subnet_id = lookup(scm_ip_restriction.value, "virtual_network_subnet_id", null)
        dynamic "headers" {
          for_each = lookup(scm_ip_restriction.value, "headers", null) != null ? [scm_ip_restriction.value.headers] : []
          content {
            x_azure_fdid      = lookup(headers.value, "x_azure_fdid", null)
            x_fd_health_probe = lookup(headers.value, "x_fd_health_probe", null)
            x_forwarded_for   = lookup(headers.value, "x_forwarded_for", null)
            x_forwarded_host  = lookup(headers.value, "x_forwarded_host", null)
          }
        }
      }
    }

    # CORS
    dynamic "cors" {
      for_each = lookup(var.site_config, "cors", null) != null ? [var.site_config.cors] : []
      content {
        allowed_origins     = lookup(cors.value, "allowed_origins", null)
        support_credentials = lookup(cors.value, "support_credentials", false)
      }
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

  # Auth Settings (same as Linux)
  dynamic "auth_settings" {
    for_each = var.auth_settings != null ? [var.auth_settings] : []
    content {
      enabled                        = auth_settings.value.enabled
      additional_login_parameters    = lookup(auth_settings.value, "additional_login_parameters", null)
      allowed_external_redirect_urls = lookup(auth_settings.value, "allowed_external_redirect_urls", null)
      default_provider              = lookup(auth_settings.value, "default_provider", null)
      issuer                        = lookup(auth_settings.value, "issuer", null)
      runtime_version               = lookup(auth_settings.value, "runtime_version", null)
      token_refresh_extension_hours = lookup(auth_settings.value, "token_refresh_extension_hours", null)
      token_store_enabled           = lookup(auth_settings.value, "token_store_enabled", false)
      unauthenticated_client_action = lookup(auth_settings.value, "unauthenticated_client_action", null)

      dynamic "active_directory" {
        for_each = lookup(auth_settings.value, "active_directory", null) != null ? [auth_settings.value.active_directory] : []
        content {
          client_id                 = active_directory.value.client_id
          client_secret             = lookup(active_directory.value, "client_secret", null)
          client_secret_setting_name = lookup(active_directory.value, "client_secret_setting_name", null)
          allowed_audiences         = lookup(active_directory.value, "allowed_audiences", null)
        }
      }
    }
  }

  # Backup
  dynamic "backup" {
    for_each = var.backup != null ? [var.backup] : []
    content {
      name                = backup.value.name
      storage_account_url = backup.value.storage_account_url
      enabled             = lookup(backup.value, "enabled", true)
      schedule {
        frequency_interval       = backup.value.schedule.frequency_interval
        frequency_unit           = backup.value.schedule.frequency_unit
        keep_at_least_one_backup = lookup(backup.value.schedule, "keep_at_least_one_backup", false)
        retention_period_days    = lookup(backup.value.schedule, "retention_period_days", 30)
        start_time               = lookup(backup.value.schedule, "start_time", null)
      }
    }
  }

  # Storage Account Mounts
  dynamic "storage_account" {
    for_each = var.storage_accounts
    content {
      name         = storage_account.value.name
      type         = storage_account.value.type
      account_name = storage_account.value.account_name
      share_name   = storage_account.value.share_name
      access_key   = lookup(storage_account.value, "access_key", null)
      mount_path   = lookup(storage_account.value, "mount_path", null)
    }
  }

  tags = var.tags
}
