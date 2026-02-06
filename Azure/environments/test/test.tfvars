# Resource Group Configuration
resource_group_name   = "rg-test-vm"
create_resource_group = true
location              = "East US"

# ============================================
# SINGLE VNET AND VM EXAMPLE
# ============================================
# This is a simple example with one VNet and one VM
# For multiple resources, see test.tfvars.example

virtual_networks = {
  "vnet1" = {
    virtual_network_name = "vnet-test"
    address_space        = ["10.0.0.0/16"]
    dns_servers          = []

    subnets = [
      {
        name             = "subnet1"
        address_prefixes = ["10.0.1.0/24"]
        create_nsg       = true
        nsg_rules = [
          {
            name                       = "SSH"
            priority                   = 1001
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            destination_port_range     = "22"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
          },
          {
            name                       = "HTTP"
            priority                   = 1002
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            destination_port_range     = "80"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
          },
          {
            name                       = "HTTPS"
            priority                   = 1003
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            destination_port_range     = "443"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
          }
        ]
      }
    ]

    create_nsgs = true
  }
}

virtual_machines = {
  "vm1" = {
    vm_name     = "vm-test-001"
    vnet_key    = "vnet1"
    subnet_name = "subnet1"
    vm_size     = "Standard_B1s"
    vm_os_type  = "Linux"

    admin_username                  = "azureuser"
    admin_password                  = "ChangeMe123!@#" # IMPORTANT: Change this password!
    disable_password_authentication = false

    enable_public_ip = true
    use_vnet_nsg     = true

    os_disk_storage_account_type = "StandardSSD_LRS"
    os_disk_size_gb              = 30

    source_image_publisher = "Canonical"
    source_image_offer     = "0001-com-ubuntu-server-jammy"
    source_image_sku       = "22_04-lts"
    source_image_version   = "latest"
  }
}

# ============================================
# TRAFFIC MANAGER CONFIGURATION
# ============================================
# Example Traffic Manager with endpoints pointing to VMs
traffic_managers = {
  # Uncomment and configure if you want to create Traffic Manager
  # "tm1" = {
  #   traffic_manager_name   = "tm-test-profile"
  #   traffic_routing_method = "Priority"  # Priority, Weighted, Performance, Geographic, Subnet, MultiValue
  #   relative_dns_name      = "tm-test-app"  # Creates: tm-test-app.trafficmanager.net
  #   ttl                    = 300
  #   
  #   monitor_config = {
  #     protocol                     = "HTTP"
  #     port                         = 80
  #     path                         = "/"
  #     interval_in_seconds          = 30
  #     timeout_in_seconds           = 10
  #     tolerated_number_of_failures = 3
  #     expected_status_code_ranges  = ["200"]
  #   }
  #   
  #   endpoints = [
  #     {
  #       name     = "vm1-endpoint"
  #       type     = "azure"
  #       vm_key   = "vm1"  # References "vm1" from virtual_machines
  #       priority = 1
  #       weight   = 1
  #       enabled  = true
  #     }
  #   ]
  # }
}

# ============================================
# FRONT DOOR CONFIGURATION
# ============================================
# Example Front Door with endpoints pointing to VMs
front_doors = {
  # Uncomment and configure if you want to create Front Door
  # "fd1" = {
  #   front_door_profile_name  = "fd-test-profile"
  #   front_door_endpoint_name = "fd-test-endpoint"
  #   sku_name                 = "Standard_AzureFrontDoor"
  #   endpoint_enabled         = true
  #   
  #   origin_groups = [
  #     {
  #       name = "backend-pool-1"
  #       health_probe = {
  #         protocol            = "Http"
  #         request_type        = "HEAD"
  #         interval_in_seconds = 100
  #         path                = "/health"
  #       }
  #       load_balancing = {
  #         additional_latency_in_milliseconds = 50
  #         sample_size                        = 4
  #         successful_samples_required        = 3
  #       }
  #     }
  #   ]
  #   
  #   origins = [
  #     {
  #       name             = "vm1-origin"
  #       origin_group_name = "backend-pool-1"
  #       vm_key           = "vm1"  # References "vm1" from virtual_machines (uses VM's public IP)
  #       http_port        = 80
  #       https_port       = 443
  #       priority         = 1
  #       weight           = 1000
  #       enabled          = true
  #     }
  #   ]
  #   
  #   routes = [
  #     {
  #       name                  = "default-route"
  #       origin_group_name     = "backend-pool-1"
  #       origin_names          = ["vm1-origin"]
  #       patterns_to_match     = ["/*"]
  #       supported_protocols   = ["Http", "Https"]
  #       forwarding_protocol   = "MatchRequest"
  #       https_redirect_enabled = true
  #       cache = {
  #         query_string_caching_behavior = "IgnoreQueryString"
  #         compression_enabled           = true
  #       }
  #     }
  #   ]
  # }
}

# ============================================
# APP SERVICES CONFIGURATION
# ============================================
# Example App Services with multiple configurations
app_services = {
  # Uncomment and configure if you want to create App Services
  # "app1" = {
  #   app_service_name         = "app-test-001"
  #   app_service_plan_name    = "plan-test-001"
  #   app_service_plan_sku_name = "B1"
  #   os_type                  = "Linux"
  #   
  #   app_settings = {
  #     "WEBSITE_NODE_DEFAULT_VERSION" = "18-lts"
  #     "ENVIRONMENT"                  = "Production"
  #   }
  #   
  #   site_config = {
  #     always_on          = true
  #     http2_enabled      = true
  #     minimum_tls_version = "1.2"
  #     websockets_enabled = true
  #   }
  #   
  #   site_config_application_stack = {
  #     node_version = "18-lts"
  #   }
  #   
  #   identity_type = "SystemAssigned"
  #   
  #   # Deployment Slots Example - Create staging and dev slots
  #   deployment_slots = [
  #     {
  #       name = "staging"
  #       app_settings = {
  #         "ENVIRONMENT" = "Staging"
  #       }
  #       site_config = {
  #         always_on = false  # Can be false for staging
  #       }
  #     },
  #     {
  #       name = "dev"
  #       app_settings = {
  #         "ENVIRONMENT" = "Development"
  #       }
  #     }
  #   ]
  # }
}

# ============================================
# MONITORING CONFIGURATION
# ============================================
# Uncomment and configure if you want to create monitoring resources

# Log Analytics Workspaces
# log_analytics_workspaces = {
#   "law1" = {
#     log_analytics_workspace_name = "law-test-workspace"
#     sku                          = "PerGB2018"
#     retention_in_days            = 30
#   }
# }

# Application Insights
# application_insights = {
#   "appinsights1" = {
#     application_insights_name = "appinsights-test"
#     application_type          = "web"
#     retention_in_days         = 90
#     log_analytics_workspace_key = "law1"  # References log_analytics_workspaces["law1"]
#   }
# }

# Diagnostic Settings
# diagnostic_settings = {
#   "vm1-diagnostics" = {
#     name                = "vm1-diagnostics"
#     target_resource_key = "vm1"  # Automatically detects it's a VM - references virtual_machines["vm1"]
#     log_analytics_workspace_key = "law1"  # References log_analytics_workspaces["law1"]
#     legacy_logs         = ["VMProtectionAlerts"]
#     legacy_metrics      = ["AllMetrics"]
#   },
#   "app1-diagnostics" = {
#     name                = "app1-diagnostics"
#     target_resource_key = "app1"  # Automatically detects it's an App Service - references app_services["app1"]
#     log_analytics_workspace_key = "law1"
#     legacy_logs         = ["AppServiceAppLogs"]
#     legacy_metrics      = ["AllMetrics"]
#   }
# }

# ============================================
# STORAGE ACCOUNTS CONFIGURATION
# ============================================
# Uncomment and configure if you want to create Storage Accounts

# storage_accounts = {
#   "sa1" = {
#     storage_account_name       = "stappservicemounts001"  # Must be globally unique
#     account_tier               = "Standard"
#     account_replication_type   = "LRS"
#     
#     # File Shares for App Service Storage Mounts
#     file_shares = [
#       {
#         name  = "app-content"
#         quota = 5120  # 5GB
#       }
#     ]
#   }
# }

# Common Tags
tags = {
  Environment = "Test"
  Project     = "Terraform-VM"
  ManagedBy   = "Terraform"
  Owner       = "YourName"
}
