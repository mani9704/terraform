# Resource Group Variables
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-test-vm"
}

variable "create_resource_group" {
  description = "Whether to create a new resource group"
  type        = bool
  default     = true
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "East US"
}

# Virtual Networks Configuration (Multiple VNets support)
variable "virtual_networks" {
  description = "Map of virtual networks to create. Key is used as reference identifier."
  type = map(object({
    virtual_network_name = string
    location             = optional(string) # If not provided, uses var.location
    address_space        = list(string)
    dns_servers          = optional(list(string), [])
    subnets = list(object({
      name                                         = string
      address_prefixes                             = list(string)
      service_endpoints                            = optional(list(string))
      service_endpoint_policy_ids                  = optional(list(string))
      private_endpoint_network_policies_enabled    = optional(bool)
      private_link_service_network_policies_enabled = optional(bool)
      delegation                                   = optional(list(object({
        name = string
        service_delegation = object({
          name    = string
          actions = optional(list(string))
        })
      })))
      create_nsg = optional(bool, false)
      nsg_rules  = optional(list(object({
        name                                       = string
        priority                                   = number
        direction                                  = string
        access                                     = string
        protocol                                   = string
        source_port_range                          = optional(string)
        source_port_ranges                         = optional(list(string))
        destination_port_range                     = optional(string)
        destination_port_ranges                    = optional(list(string))
        source_address_prefix                      = optional(string)
        source_address_prefixes                    = optional(list(string))
        destination_address_prefix                 = optional(string)
        destination_address_prefixes               = optional(list(string))
        source_application_security_group_ids      = optional(list(string))
        destination_application_security_group_ids = optional(list(string))
      })), [])
      nsg_tags = optional(map(string), {})
    }))
    create_nsgs = optional(bool, true)
    tags        = optional(map(string), {})
  }))
  default = {}
}

# Virtual Machines Configuration (Multiple VMs support)
variable "virtual_machines" {
  description = "Map of virtual machines to create. Key is used as reference identifier."
  type = map(object({
    vm_name    = string
    vnet_key   = string # Reference to key in virtual_networks map
    subnet_name = string # Subnet name within the referenced VNet
    location    = optional(string) # If not provided, uses var.location
    vm_size     = optional(string, "Standard_B1s")
    vm_os_type  = optional(string, "Linux")
    
    # Admin Credentials
    admin_username                  = string
    admin_password                  = optional(string)
    ssh_public_key                  = optional(string)
    disable_password_authentication = optional(bool, true)
    
    # Network Configuration
    enable_public_ip            = optional(bool, true)
    use_vnet_nsg               = optional(bool, true)
    create_network_security_group = optional(bool, false)
    nsg_rules                   = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string, "*")
      source_address_prefix      = optional(string, "*")
      destination_address_prefix = optional(string, "*")
    })), [])
    
    # OS Disk Configuration
    os_disk_storage_account_type = optional(string, "StandardSSD_LRS")
    os_disk_size_gb              = optional(number, 30)
    
    # Source Image Configuration
    source_image_publisher = optional(string, "Canonical")
    source_image_offer     = optional(string, "0001-com-ubuntu-server-jammy")
    source_image_sku       = optional(string, "22_04-lts")
    source_image_version   = optional(string, "latest")
    
    # Data Disks
    data_disks = optional(list(object({
      disk_size_gb         = number
      storage_account_type = string
      caching              = string
    })), [])
    
    # Tags
    tags = optional(map(string), {})
  }))
  default = {}
}

# Traffic Manager Configuration (Multiple Traffic Managers support)
variable "traffic_managers" {
  description = "Map of Traffic Manager profiles to create. Key is used as reference identifier."
  type = map(object({
    traffic_manager_name   = string
    traffic_routing_method = optional(string, "Performance") # Priority, Weighted, Performance, Geographic, Subnet, MultiValue
    relative_dns_name      = string
    ttl                    = optional(number, 300)
    
    monitor_config = optional(object({
      protocol                     = string
      port                         = number
      path                         = optional(string, "/")
      interval_in_seconds          = optional(number, 30)
      timeout_in_seconds           = optional(number, 10)
      tolerated_number_of_failures = optional(number, 3)
      expected_status_code_ranges  = optional(list(string), ["200"])
      custom_headers = optional(list(object({
        name  = string
        value = string
      })), [])
    }), {
      protocol                     = "HTTP"
      port                         = 80
      path                         = "/"
      interval_in_seconds          = 30
      timeout_in_seconds           = 10
      tolerated_number_of_failures = 3
      expected_status_code_ranges  = ["200"]
      custom_headers               = []
    })
    
    endpoints = optional(list(object({
      name     = string
      type     = string # "azure", "external", or "nested"
      enabled  = optional(bool, true)
      weight   = optional(number, 1)
      priority = optional(number, null)
      
      # For Azure/Nested endpoints - can reference VM or App Service by key
      app_service_key    = optional(string, null) # Reference to key in app_services map (recommended for App Services)
      vm_key             = optional(string, null) # Reference to key in virtual_machines map
      target_resource_id = optional(string, null) # Or provide direct resource ID
      
      # For External endpoints
      target = optional(string, null)
      
      # For Nested endpoints
      minimum_child_endpoints               = optional(number, 1)
      minimum_required_child_endpoints_ipv4 = optional(number, null)
      minimum_required_child_endpoints_ipv6 = optional(number, null)
      
      # Optional: Custom headers
      custom_headers = optional(list(object({
        name  = string
        value = string
      })), [])
      
      # Optional: Subnets (for Subnet routing method)
      subnets = optional(list(object({
        first = string
        last  = optional(string, null)
        scope = optional(number, null)
      })), [])
    })), [])
    
    tags = optional(map(string), {})
  }))
  default = {}
}

# Front Door Configuration (Multiple Front Doors support)
variable "front_doors" {
  description = "Map of Front Door profiles to create. Key is used as reference identifier."
  type = map(object({
    front_door_profile_name   = string
    front_door_endpoint_name  = string
    sku_name                  = optional(string, "Standard_AzureFrontDoor")
    response_timeout_seconds  = optional(number, 60)
    endpoint_enabled          = optional(bool, true)
    
    origin_groups = optional(list(object({
      name                                          = string
      session_affinity_enabled                     = optional(bool, false)
      restore_traffic_time_to_healed_or_new_endpoint_in_minutes = optional(number, 10)
      load_balancing = optional(object({
        additional_latency_in_milliseconds = optional(number, 50)
        sample_size                        = optional(number, 4)
        successful_samples_required        = optional(number, 3)
      }), null)
      health_probe = optional(object({
        protocol            = optional(string, "Http")
        request_type        = optional(string, "HEAD")
        interval_in_seconds = optional(number, 100)
        path                = optional(string, "/")
      }), null)
    })), [])
    
    origins = optional(list(object({
      name                            = string
      origin_group_name               = string
      
      # Origin type options (choose one):
      app_service_key                 = optional(string, null) # Reference to App Service key (uses App Service resource ID - recommended)
      vm_key                          = optional(string, null) # Reference to VM key (uses VM public IP by default)
      use_vm_resource_id              = optional(bool, false) # If true with vm_key, uses VM resource ID instead of public IP
      target_resource_id              = optional(string, null) # Direct Azure resource ID (App Service or VM)
      host_name                       = optional(string, null) # Direct hostname/IP for external origins
      
      http_port                       = optional(number, 80)
      https_port                      = optional(number, 443)
      origin_host_header              = optional(string, null)
      priority                        = optional(number, 1)
      weight                          = optional(number, 1000)
      enabled                         = optional(bool, true)
      certificate_name_check_enabled  = optional(bool, true)
      private_link = optional(object({
        location               = string
        private_link_target_id = string
        request_message        = optional(string, "Please approve")
        target_type            = optional(string, null)
      }), null)
    })), [])
    
    custom_domains = optional(list(object({
      name      = string
      host_name = string
      dns_zone_id = optional(string, null)
      tls = optional(object({
        certificate_type         = string
        minimum_tls_version      = optional(string, "TLS12")
        cdn_frontdoor_secret_id  = optional(string, null)
      }), null)
    })), [])
    
    # Security Policies (Multiple WAF Policies Support)
    security_policies = optional(list(object({
      name         = string
      waf_policy_id = string  # Resource ID of the WAF policy
      associations = optional(list(object({
        custom_domain_names = optional(list(string), [])  # List of custom domain names to associate
        patterns_to_match   = optional(list(string), ["/*"])  # URL patterns to match
      })), [])
    })), [])
    
    # Legacy WAF Policy (for backward compatibility)
    waf_policy_id        = optional(string, null)
    waf_patterns_to_match = optional(list(string), ["/*"])
    
    routes = optional(list(object({
      name                    = string
      origin_group_name       = string
      origin_names            = list(string)
      enabled                 = optional(bool, true)
      forwarding_protocol     = optional(string, "MatchRequest")
      https_redirect_enabled  = optional(bool, false)
      patterns_to_match       = optional(list(string), ["/*"])
      supported_protocols     = optional(list(string), ["Http", "Https"])
      custom_domain_names     = optional(list(string), null)
      cache = optional(object({
        query_string_caching_behavior = optional(string, "IgnoreQueryString")
        query_strings                 = optional(list(string), null)
        compression_enabled           = optional(bool, true)
        content_types_to_compress     = optional(list(string), [])
      }), null)
    })), [])
    
    rule_sets = optional(list(object({
      name = string
    })), [])
    
    rules = optional(list(object({
      name                = string
      rule_set_name       = string
      order               = optional(number, 1)
      behavior_on_match   = optional(string, "Continue")
      conditions          = optional(list(any), [])
      actions             = optional(list(any), [])
    })), [])
    
    tags = optional(map(string), {})
  }))
  default = {}
}

# App Services Configuration (Multiple App Services support)
variable "app_services" {
  description = "Map of App Services to create. Key is used as reference identifier."
  type = map(object({
    app_service_name = string
    location         = optional(string) # If not provided, uses var.location
    
    # App Service Plan Configuration
    create_app_service_plan = optional(bool, true)
    app_service_plan_id     = optional(string, null) # Use existing plan if provided
    app_service_plan_name   = optional(string, null)
    app_service_plan_os_type = optional(string, "Linux")
    app_service_plan_sku_name = optional(string, "B1")
    app_service_plan_config = optional(object({
      zone_balancing_enabled  = optional(bool, false)
      per_site_scaling_enabled = optional(bool, false)
    }), {})
    
    # App Service Configuration
    os_type                          = optional(string, "Linux")
    https_only                       = optional(bool, true)
    enabled                          = optional(bool, true)
    public_network_access_enabled    = optional(bool, true)
    client_certificate_enabled       = optional(bool, false)
    client_certificate_mode          = optional(string, null)
    client_certificate_exclusion_paths = optional(list(string), null)
    
    # Application Insights Integration
    app_insights_key                 = optional(string, null) # Reference to application_insights key - auto-injects instrumentation key and connection string
    
    # App Settings and Connection Strings
    # Note: If app_insights_key is provided, APPINSIGHTS_INSTRUMENTATIONKEY and APPLICATIONINSIGHTS_CONNECTION_STRING
    # will be automatically added to app_settings and site_config
    app_settings = optional(map(string), {})
    connection_strings = optional(list(object({
      name  = string
      type  = string
      value = string
    })), [])
    
    # Site Config
    site_config = optional(object({
      always_on                                 = optional(bool, true)
      api_definition_url                        = optional(string, null)
      application_insights_connection_string    = optional(string, null)
      application_insights_key                  = optional(string, null)
      health_check_path                         = optional(string, null)
      http2_enabled                             = optional(bool, false)
      minimum_tls_version                       = optional(string, "1.2")
      scm_minimum_tls_version                   = optional(string, "1.2")
      websockets_enabled                        = optional(bool, false)
      ip_restrictions = optional(list(object({
        action                    = optional(string, "Allow")
        ip_address                = optional(string, null)
        name                      = optional(string, null)
        priority                  = optional(number, null)
        service_tag               = optional(string, null)
        virtual_network_subnet_id = optional(string, null)
      })), [])
      cors = optional(object({
        allowed_origins     = optional(list(string), null)
        support_credentials = optional(bool, false)
      }), null)
    }), {})
    
    site_config_application_stack = optional(object({
      docker_image   = optional(string, null)
      docker_image_tag = optional(string, null)
      dotnet_version = optional(string, null)
      java_version   = optional(string, null)
      node_version   = optional(string, null)
      php_version    = optional(string, null)
      python_version = optional(string, null)
      go_version     = optional(string, null)
    }), null)
    
    # Identity
    identity_type = optional(string, null)
    identity_ids  = optional(list(string), null)
    
    # Auth Settings
    auth_settings = optional(object({
      enabled = bool
      active_directory = optional(object({
        client_id                 = string
        client_secret_setting_name = optional(string, null)
        allowed_audiences         = optional(list(string), null)
      }), null)
    }), null)
    
    # Backup
    backup = optional(object({
      name                = string
      storage_account_url = string
      enabled             = optional(bool, true)
      schedule = object({
        frequency_interval = number
        frequency_unit     = string
        retention_period_days = optional(number, 30)
      })
    }), null)
    
    # Storage Accounts (for storage mounts in App Service)
    storage_accounts = optional(list(object({
      name                = string  # Name of the mount point
      type                = string  # AzureFiles or AzureBlob
      # Option 1: Reference Storage Account by key (Recommended)
      storage_account_key = optional(string, null)  # Reference to storage_accounts key (e.g., "sa1")
      file_share_key      = optional(string, null)  # Optional: Specific file share key from storage_account_key
      # Option 2: Direct values (fallback)
      account_name        = optional(string, null)  # Direct storage account name
      share_name          = optional(string, null)  # Direct file share name (alternative to file_share_key)
      file_share_name     = optional(string, null)  # Alternative name for share_name
      access_key          = optional(string, null)  # Direct access key (if not using storage_account_key)
      mount_path          = optional(string, null)  # Mount path in App Service
    })), [])
    
    # Deployment Slots
    deployment_slots = optional(list(object({
      name                          = string
      https_only                    = optional(bool)
      client_certificate_enabled    = optional(bool)
      enabled                       = optional(bool, true)
      public_network_access_enabled = optional(bool)
      app_settings                  = optional(map(string), {})
      connection_strings = optional(list(object({
        name  = string
        type  = string
        value = string
      })), [])
      site_config = optional(object({
        always_on                                 = optional(bool)
        application_insights_connection_string    = optional(string)
        health_check_path                         = optional(string)
        http2_enabled                             = optional(bool)
        minimum_tls_version                       = optional(string)
        websockets_enabled                        = optional(bool)
      }), {})
      site_config_application_stack = optional(object({
        node_version   = optional(string)
        python_version = optional(string)
        dotnet_version = optional(string)
      }), null)
      identity_type = optional(string)
      tags = optional(map(string), {})
    })), [])
    
    tags = optional(map(string), {})
  }))
  default = {}
}

# Log Analytics Workspaces Configuration
variable "log_analytics_workspaces" {
  description = "Map of Log Analytics Workspaces to create. Key is used as reference identifier."
  type = map(object({
    log_analytics_workspace_name = string
    location                     = optional(string) # If not provided, uses var.location
    sku                          = optional(string, "PerGB2018")
    retention_in_days            = optional(number, 30)
    allow_resource_only_permissions = optional(bool, true)
    daily_quota_gb               = optional(number, null)
    internet_ingestion_enabled   = optional(bool, true)
    internet_query_enabled       = optional(bool, true)
    local_authentication_disabled = optional(bool, false)
    reservation_capacity_in_gb_per_day = optional(number, null)
    solutions = optional(list(object({
      solution_name = string
      publisher     = string
      product       = string
      tags          = optional(map(string), {})
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

# Application Insights Configuration
variable "application_insights" {
  description = "Map of Application Insights resources to create. Key is used as reference identifier."
  type = map(object({
    application_insights_name             = string
    location                              = optional(string) # If not provided, uses var.location
    application_type                      = optional(string, "web")
    daily_data_cap_in_gb                  = optional(number, null)
    daily_data_cap_notifications_disabled = optional(bool, false)
    retention_in_days                     = optional(number, 90)
    sampling_percentage                   = optional(number, null)
    disable_ip_masking                    = optional(bool, false)
    log_analytics_workspace_id            = optional(string, null) # Direct ID
    log_analytics_workspace_key           = optional(string, null) # Reference to log_analytics_workspaces key
    local_authentication_disabled         = optional(bool, false)
    internet_ingestion_enabled            = optional(bool, true)
    internet_query_enabled                = optional(bool, true)
    force_customer_storage_for_profiler   = optional(bool, false)
    web_tests = optional(list(object({
      name          = string
      kind          = string
      configuration = string
      frequency     = optional(number, 300)
      timeout       = optional(number, 60)
      enabled       = optional(bool, true)
      geo_locations = optional(list(string), ["us-ca-sjc-azr"])
      retry_enabled = optional(bool, false)
      description   = optional(string, null)
      tags          = optional(map(string), {})
    })), [])
    api_keys = optional(list(object({
      name             = string
      read_permissions  = optional(list(string), [])
      write_permissions = optional(list(string), [])
    })), [])
    smart_detection_rules = optional(list(object({
      name                            = string
      enabled                         = optional(bool, true)
      send_emails_to_subscription_owners = optional(bool, false)
      additional_email_recipients     = optional(list(string), [])
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

# Diagnostic Settings Configuration
variable "diagnostic_settings" {
  description = "Map of diagnostic settings to create for Azure resources (VMs, App Services, etc.). Key is used as reference identifier."
  type = map(object({
    name = string
    # Target resource - can reference by key or provide direct ID
    target_resource_id   = optional(string, null) # Direct resource ID
    target_resource_key  = optional(string, null) # Reference to resource by key - automatically detects type (VM, App Service, etc.)
    target_resource_type = optional(string, null) # Optional: explicitly specify type ("vm", "app_service") if auto-detection fails
    
    # Destination - Log Analytics Workspace (can reference by key or provide direct ID)
    log_analytics_workspace_id     = optional(string, null) # Direct workspace ID
    log_analytics_workspace_key    = optional(string, null) # Reference to log_analytics_workspaces key (e.g., "law1")
    
    # Other destinations
    eventhub_name                  = optional(string, null)
    eventhub_authorization_rule_id = optional(string, null)
    storage_account_id             = optional(string, null)
    partner_solution_id            = optional(string, null)
    
    log_categories = optional(list(object({
      category      = string
      category_group = optional(string, null)
      retention_policy = object({
        enabled = optional(bool, false)
        days    = optional(number, 0)
      })
    })), [])
    metric_categories = optional(list(object({
      category = string
      enabled  = optional(bool, true)
      retention_policy = object({
        enabled = optional(bool, false)
        days    = optional(number, 0)
      })
    })), [])
    legacy_logs    = optional(list(string), [])
    legacy_metrics = optional(list(string), [])
  }))
  default = {}
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Test"
    Project     = "Terraform-VM"
    ManagedBy   = "Terraform"
  }
}
