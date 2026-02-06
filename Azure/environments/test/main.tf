# Create Resource Group (if needed)
# DEPENDENCY: This is created FIRST, all other resources depend on it
resource "azurerm_resource_group" "main" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Call the VNet module - Create multiple VNets using for_each
# DEPENDENCY ORDER: Resource Group → VNet → Subnet
# This module creates VNet first, then Subnets inside it
module "virtual_network" {
  source   = "../../modules/networking/VNet"
  for_each = var.virtual_networks

  # Resource Group Configuration
  # DEPENDENCY: Resource Group must exist before creating VNet
  resource_group_name   = var.resource_group_name
  create_resource_group = false # Use existing resource group
  location              = each.value.location != null ? each.value.location : var.location

  # Virtual Network Configuration
  virtual_network_name = each.value.virtual_network_name
  address_space        = each.value.address_space
  dns_servers          = lookup(each.value, "dns_servers", [])

  # Subnet Configuration
  subnets = each.value.subnets

  # NSG Configuration
  create_nsgs = lookup(each.value, "create_nsgs", true)

  # Tags - Merge common tags with VNet-specific tags
  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

# Call the VM module - Create multiple VMs using for_each
# DEPENDENCY ORDER: Resource Group → VNet → Subnet → VM
# VMs depend on VNet/Subnets (explicit dependency ensures VNet is created first)
module "virtual_machine" {
  source   = "../../modules/compute/VM"
  for_each = var.virtual_machines

  # Explicit dependency: Wait for VNet module to complete (which creates Subnets)
  depends_on = [module.virtual_network]

  # Resource Group Configuration
  resource_group_name   = var.resource_group_name
  create_resource_group = false # Use existing resource group
  location              = each.value.location != null ? each.value.location : var.location

  # Virtual Machine Configuration
  vm_name    = each.value.vm_name
  vm_size    = lookup(each.value, "vm_size", "Standard_B1s")
  vm_os_type = lookup(each.value, "vm_os_type", "Linux")

  # Admin Credentials
  admin_username                  = each.value.admin_username
  admin_password                  = lookup(each.value, "admin_password", null)
  ssh_public_key                  = lookup(each.value, "ssh_public_key", null)
  disable_password_authentication = lookup(each.value, "disable_password_authentication", true)

  # Network Configuration - Reference VNet by key
  subnet_id = length(module.virtual_network) > 0 && contains(keys(module.virtual_network), each.value.vnet_key) ? (
    contains(keys(module.virtual_network[each.value.vnet_key].subnet_ids), each.value.subnet_name) ? (
      module.virtual_network[each.value.vnet_key].subnet_ids[each.value.subnet_name]
    ) : null
  ) : null
  enable_public_ip = lookup(each.value, "enable_public_ip", true)

  # Use NSG from VNet if specified
  network_security_group_id = lookup(each.value, "use_vnet_nsg", true) && length(module.virtual_network) > 0 && contains(keys(module.virtual_network), each.value.vnet_key) ? (
    contains(keys(module.virtual_network[each.value.vnet_key].network_security_group_ids), each.value.subnet_name) ? (
      module.virtual_network[each.value.vnet_key].network_security_group_ids[each.value.subnet_name]
    ) : null
  ) : null

  # Network Security Group Configuration (only if not using VNet NSG)
  create_network_security_group = lookup(each.value, "use_vnet_nsg", true) ? false : lookup(each.value, "create_network_security_group", false)
  nsg_rules                     = lookup(each.value, "nsg_rules", [])

  # OS Disk Configuration
  os_disk_storage_account_type = lookup(each.value, "os_disk_storage_account_type", "StandardSSD_LRS")
  os_disk_size_gb              = lookup(each.value, "os_disk_size_gb", 30)

  # Source Image Configuration
  source_image_publisher = lookup(each.value, "source_image_publisher", "Canonical")
  source_image_offer     = lookup(each.value, "source_image_offer", "0001-com-ubuntu-server-jammy")
  source_image_sku       = lookup(each.value, "source_image_sku", "22_04-lts")
  source_image_version   = lookup(each.value, "source_image_version", "latest")

  # Data Disks
  data_disks = lookup(each.value, "data_disks", [])

  # Tags - Merge common tags with VM-specific tags
  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

# Call the Traffic Manager module - Create multiple Traffic Managers using for_each
# DEPENDENCY ORDER: Resource Group → VNet → Subnet → VM → App Service → Traffic Manager
# Traffic Manager endpoints can reference VMs or App Services, so both must be created first
module "traffic_manager" {
  source   = "../../modules/networking/TrafficManager"
  for_each = var.traffic_managers

  # Explicit dependencies: Wait for VM and App Service modules to complete
  # Traffic Manager endpoints may reference VMs or App Services by resource ID
  depends_on = [module.virtual_machine, module.app_service]

  # Resource Group Configuration
  resource_group_name   = var.resource_group_name
  create_resource_group = false    # Use existing resource group
  location              = "global" # Traffic Manager is always global

  # Traffic Manager Configuration
  traffic_manager_name   = each.value.traffic_manager_name
  traffic_routing_method = lookup(each.value, "traffic_routing_method", "Performance")
  relative_dns_name      = each.value.relative_dns_name
  ttl                    = lookup(each.value, "ttl", 300)

  # Monitor Configuration
  monitor_config = lookup(each.value, "monitor_config", {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 3
    expected_status_code_ranges  = ["200"]
    custom_headers               = []
  })

  # Endpoints - Can reference VMs or App Services by their keys
  endpoints = [
    for endpoint in lookup(each.value, "endpoints", []) : {
      name     = endpoint.name
      type     = endpoint.type
      enabled  = lookup(endpoint, "enabled", true)
      weight   = lookup(endpoint, "weight", 1)
      priority = lookup(endpoint, "priority", null)

      # For Azure endpoints - can reference VM or App Service by key, or use direct resource ID
      # Priority: app_service_key > vm_key > target_resource_id
      target_resource_id = endpoint.type == "azure" ? (
        endpoint.app_service_key != null && length(module.app_service) > 0 && contains(keys(module.app_service), endpoint.app_service_key) ? (
          module.app_service[endpoint.app_service_key].app_service_id
          ) : (
          endpoint.vm_key != null && length(module.virtual_machine) > 0 && contains(keys(module.virtual_machine), endpoint.vm_key) ? (
            module.virtual_machine[endpoint.vm_key].vm_id
            ) : (
            endpoint.target_resource_id
          )
        )
        ) : (
        # For Nested endpoints - can also reference App Service or VM
        endpoint.type == "nested" ? (
          endpoint.app_service_key != null && length(module.app_service) > 0 && contains(keys(module.app_service), endpoint.app_service_key) ? (
            module.app_service[endpoint.app_service_key].app_service_id
            ) : (
            endpoint.vm_key != null && length(module.virtual_machine) > 0 && contains(keys(module.virtual_machine), endpoint.vm_key) ? (
              module.virtual_machine[endpoint.vm_key].vm_id
              ) : (
              endpoint.target_resource_id
            )
          )
        ) : null
      )

      # For External endpoints
      target = endpoint.type == "external" ? endpoint.target : null

      # For Nested endpoints
      minimum_child_endpoints               = lookup(endpoint, "minimum_child_endpoints", 1)
      minimum_required_child_endpoints_ipv4 = lookup(endpoint, "minimum_required_child_endpoints_ipv4", null)
      minimum_required_child_endpoints_ipv6 = lookup(endpoint, "minimum_required_child_endpoints_ipv6", null)

      # Optional configurations
      custom_headers = lookup(endpoint, "custom_headers", [])
      subnets        = lookup(endpoint, "subnets", [])
    }
  ]

  # Tags - Merge common tags with Traffic Manager-specific tags
  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

# Call the Front Door module - Create multiple Front Doors using for_each
# DEPENDENCY ORDER: Resource Group → VNet → Subnet → VM → App Service → Front Door
# Front Door origins can reference VMs (by public IP) or App Services (by resource ID)
module "front_door" {
  source   = "../../modules/networking/FrontDoor"
  for_each = var.front_doors

  # Explicit dependencies: Wait for VM and App Service modules to complete
  # Front Door origins may reference VMs or App Services
  depends_on = [module.virtual_machine, module.app_service]

  # Resource Group Configuration
  resource_group_name   = var.resource_group_name
  create_resource_group = false    # Use existing resource group
  location              = "global" # Front Door is always global

  # Front Door Profile Configuration
  front_door_profile_name  = each.value.front_door_profile_name
  sku_name                 = lookup(each.value, "sku_name", "Standard_AzureFrontDoor")
  response_timeout_seconds = lookup(each.value, "response_timeout_seconds", 60)

  # Front Door Endpoint Configuration
  front_door_endpoint_name = each.value.front_door_endpoint_name
  endpoint_enabled         = lookup(each.value, "endpoint_enabled", true)

  # Origin Groups - Can reference VM origins
  origin_groups = [
    for group in lookup(each.value, "origin_groups", []) : {
      name                                                      = group.name
      session_affinity_enabled                                  = lookup(group, "session_affinity_enabled", false)
      restore_traffic_time_to_healed_or_new_endpoint_in_minutes = lookup(group, "restore_traffic_time_to_healed_or_new_endpoint_in_minutes", 10)
      load_balancing                                            = lookup(group, "load_balancing", null)
      health_probe                                              = lookup(group, "health_probe", null)
    }
  ]

  # Origins - Can reference VMs (by public IP) or App Services (by resource ID)
  # Multiple Front Doors can reference the same VMs/App Services - each Front Door creates its own resources
  origins = [
    for origin in lookup(each.value, "origins", []) : {
      name              = origin.name
      origin_group_name = origin.origin_group_name

      # Resolve host_name for the origin
      host_name = origin.app_service_key != null && length(module.app_service) > 0 && contains(keys(module.app_service), origin.app_service_key) ? (
        module.app_service[origin.app_service_key].app_service_default_host_name
        ) : (
        origin.vm_key != null && length(module.virtual_machine) > 0 && contains(keys(module.virtual_machine), origin.vm_key) ? (
          module.virtual_machine[origin.vm_key].vm_public_ip != null ?
          module.virtual_machine[origin.vm_key].vm_public_ip :
          null
          ) : (
          lookup(origin, "host_name", null)
        )
      )

      http_port                      = lookup(origin, "http_port", 80)
      https_port                     = lookup(origin, "https_port", 443)
      origin_host_header             = lookup(origin, "origin_host_header", null)
      priority                       = lookup(origin, "priority", 1)
      weight                         = lookup(origin, "weight", 1000)
      enabled                        = lookup(origin, "enabled", true)
      certificate_name_check_enabled = lookup(origin, "certificate_name_check_enabled", true)
      private_link                   = lookup(origin, "private_link", null)
    }
  ]

  # Custom Domains
  custom_domains = lookup(each.value, "custom_domains", [])

  # Security Policies (Multiple WAF Policies Support)
  security_policies = lookup(each.value, "security_policies", [])

  # Legacy WAF Policy (for backward compatibility)
  waf_policy_id         = lookup(each.value, "waf_policy_id", null)
  waf_patterns_to_match = lookup(each.value, "waf_patterns_to_match", ["/*"])

  # Routes
  routes = lookup(each.value, "routes", [])

  # Rule Sets
  rule_sets = lookup(each.value, "rule_sets", [])

  # Rules
  rules = lookup(each.value, "rules", [])

  # Tags - Merge common tags with Front Door-specific tags
  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

# Call the Storage Account module - Create multiple Storage Accounts using for_each
# DEPENDENCY ORDER: Resource Group → Storage Account
module "storage_account" {
  source   = "../../modules/storage/StorageAccount"
  for_each = var.storage_accounts

  # Resource Group Configuration
  resource_group_name   = var.resource_group_name
  create_resource_group = false # Use existing resource group
  location              = each.value.location != null ? each.value.location : var.location

  # Storage Account Configuration
  storage_account_name          = each.value.storage_account_name
  account_tier                  = lookup(each.value, "account_tier", "Standard")
  account_replication_type      = lookup(each.value, "account_replication_type", "LRS")
  account_kind                  = lookup(each.value, "account_kind", "StorageV2")
  access_tier                   = lookup(each.value, "access_tier", "Hot")
  enable_https_traffic_only     = lookup(each.value, "enable_https_traffic_only", true)
  min_tls_version               = lookup(each.value, "min_tls_version", "TLS1_2")
  shared_access_key_enabled     = lookup(each.value, "shared_access_key_enabled", true)
  public_network_access_enabled = lookup(each.value, "public_network_access_enabled", true)

  # Containers
  containers = lookup(each.value, "containers", [])

  # File Shares (for App Service Storage Mounts)
  file_shares = lookup(each.value, "file_shares", [])

  # Tables
  tables = lookup(each.value, "tables", [])

  # Queues
  queues = lookup(each.value, "queues", [])

  # Tags
  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

# Call the App Service module - Create multiple App Services using for_each
# DEPENDENCY ORDER: Resource Group → Storage Account → Application Insights → App Service Plan → App Service
module "app_service" {
  source   = "../../modules/compute/AppService"
  for_each = var.app_services

  # Explicit dependencies: Wait for Storage Accounts and Application Insights
  # Application Insights must be created first so App Service can reference it
  depends_on = [module.storage_account, module.application_insights]

  # Resource Group Configuration
  resource_group_name   = var.resource_group_name
  create_resource_group = false # Use existing resource group
  location              = each.value.location != null ? each.value.location : var.location

  # App Service Plan Configuration
  create_app_service_plan   = lookup(each.value, "create_app_service_plan", true)
  app_service_plan_id       = lookup(each.value, "app_service_plan_id", null)
  app_service_plan_name     = lookup(each.value, "app_service_plan_name", null)
  app_service_plan_os_type  = lookup(each.value, "app_service_plan_os_type", "Linux")
  app_service_plan_sku_name = lookup(each.value, "app_service_plan_sku_name", "B1")
  app_service_plan_config   = lookup(each.value, "app_service_plan_config", {})

  # App Service Configuration
  app_service_name = each.value.app_service_name
  os_type          = lookup(each.value, "os_type", "Linux")

  # Basic Settings
  https_only                         = lookup(each.value, "https_only", true)
  enabled                            = lookup(each.value, "enabled", true)
  public_network_access_enabled      = lookup(each.value, "public_network_access_enabled", true)
  client_certificate_enabled         = lookup(each.value, "client_certificate_enabled", false)
  client_certificate_mode            = lookup(each.value, "client_certificate_mode", null)
  client_certificate_exclusion_paths = lookup(each.value, "client_certificate_exclusion_paths", null)

  # App Settings and Connection Strings
  # Automatically inject Application Insights settings if app_insights_key is provided
  app_settings = merge(
    # Auto-inject Application Insights settings
    lookup(each.value, "app_insights_key", null) != null && length(module.application_insights) > 0 ? (
      contains(keys(module.application_insights), each.value.app_insights_key) ? {
        "APPINSIGHTS_INSTRUMENTATIONKEY"        = module.application_insights[each.value.app_insights_key].application_insights_instrumentation_key
        "APPLICATIONINSIGHTS_CONNECTION_STRING" = module.application_insights[each.value.app_insights_key].application_insights_connection_string
      } : {}
    ) : {},
    # User-provided app settings (can override auto-injected settings)
    lookup(each.value, "app_settings", {})
  )
  connection_strings = lookup(each.value, "connection_strings", [])

  # Site Config
  site_config                   = lookup(each.value, "site_config", {})
  site_config_application_stack = lookup(each.value, "site_config_application_stack", null)

  # Identity
  identity_type = lookup(each.value, "identity_type", null)
  identity_ids  = lookup(each.value, "identity_ids", null)

  # Auth Settings
  auth_settings = lookup(each.value, "auth_settings", null)

  # Backup
  backup = lookup(each.value, "backup", null)

  # Storage Accounts - Convert storage_account_key references to actual storage account details
  # Support for storage mounts: Can reference storage account by key
  storage_accounts = [
    for sa in lookup(each.value, "storage_accounts", []) : {
      name = sa.name
      type = sa.type
      account_name = lookup(sa, "storage_account_key", null) != null && length(module.storage_account) > 0 && contains(keys(module.storage_account), sa.storage_account_key) ? (
        module.storage_account[sa.storage_account_key].storage_account_name
        ) : (
        lookup(sa, "account_name", null)
      )
      share_name = lookup(sa, "file_share_key", null) != null && length(module.storage_account) > 0 && contains(keys(module.storage_account), sa.storage_account_key) ? (
        contains(keys(module.storage_account[sa.storage_account_key].file_share_names), sa.file_share_key) ? (
          module.storage_account[sa.storage_account_key].file_share_names[sa.file_share_key]
        ) : null
        ) : (
        lookup(sa, "file_share_name", null) != null ? sa.file_share_name : (
          # If storage_account_key is provided, get first file share from that account
          lookup(sa, "storage_account_key", null) != null && length(module.storage_account) > 0 && contains(keys(module.storage_account), sa.storage_account_key) && length(module.storage_account[sa.storage_account_key].file_share_names) > 0 ? (
            values(module.storage_account[sa.storage_account_key].file_share_names)[0]
            ) : (
            lookup(sa, "share_name", null)
          )
        )
      )
      access_key = lookup(sa, "storage_account_key", null) != null && length(module.storage_account) > 0 && contains(keys(module.storage_account), sa.storage_account_key) ? (
        module.storage_account[sa.storage_account_key].primary_access_key
      ) : lookup(sa, "access_key", null)
      mount_path = lookup(sa, "mount_path", null)
    }
  ]

  # Deployment Slots
  deployment_slots = lookup(each.value, "deployment_slots", [])

  # Tags - Merge common tags with App Service-specific tags
  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

# ============================================
# MONITORING MODULES
# ============================================

# Call the Log Analytics Workspace module - Create multiple workspaces using for_each
module "log_analytics_workspace" {
  source   = "../../modules/monitoring/LogAnalytics"
  for_each = var.log_analytics_workspaces

  # Resource Group Configuration
  resource_group_name   = var.resource_group_name
  create_resource_group = false # Use existing resource group
  location              = each.value.location != null ? each.value.location : var.location

  # Log Analytics Workspace Configuration
  log_analytics_workspace_name       = each.value.log_analytics_workspace_name
  sku                                = lookup(each.value, "sku", "PerGB2018")
  retention_in_days                  = lookup(each.value, "retention_in_days", 30)
  allow_resource_only_permissions    = lookup(each.value, "allow_resource_only_permissions", true)
  daily_quota_gb                     = lookup(each.value, "daily_quota_gb", null)
  internet_ingestion_enabled         = lookup(each.value, "internet_ingestion_enabled", true)
  internet_query_enabled             = lookup(each.value, "internet_query_enabled", true)
  local_authentication_disabled      = lookup(each.value, "local_authentication_disabled", false)
  reservation_capacity_in_gb_per_day = lookup(each.value, "reservation_capacity_in_gb_per_day", null)

  # Solutions
  solutions = lookup(each.value, "solutions", [])

  # Tags
  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

# Call the Application Insights module - Create multiple Application Insights using for_each
# DEPENDENCY ORDER: Resource Group → Log Analytics Workspace → Application Insights
module "application_insights" {
  source   = "../../modules/monitoring/ApplicationInsights"
  for_each = var.application_insights

  # Explicit dependency: Wait for Log Analytics Workspace if Application Insights uses it
  depends_on = [module.log_analytics_workspace]

  # Resource Group Configuration
  resource_group_name   = var.resource_group_name
  create_resource_group = false # Use existing resource group
  location              = each.value.location != null ? each.value.location : var.location

  # Application Insights Configuration
  application_insights_name             = each.value.application_insights_name
  application_type                      = lookup(each.value, "application_type", "web")
  daily_data_cap_in_gb                  = lookup(each.value, "daily_data_cap_in_gb", null)
  daily_data_cap_notifications_disabled = lookup(each.value, "daily_data_cap_notifications_disabled", false)
  retention_in_days                     = lookup(each.value, "retention_in_days", 90)
  sampling_percentage                   = lookup(each.value, "sampling_percentage", null)
  disable_ip_masking                    = lookup(each.value, "disable_ip_masking", false)
  log_analytics_workspace_id = lookup(each.value, "log_analytics_workspace_key", null) != null && length(module.log_analytics_workspace) > 0 && contains(keys(module.log_analytics_workspace), each.value.log_analytics_workspace_key) ? (
    module.log_analytics_workspace[each.value.log_analytics_workspace_key].log_analytics_workspace_id
  ) : lookup(each.value, "log_analytics_workspace_id", null)
  local_authentication_disabled       = lookup(each.value, "local_authentication_disabled", false)
  internet_ingestion_enabled          = lookup(each.value, "internet_ingestion_enabled", true)
  internet_query_enabled              = lookup(each.value, "internet_query_enabled", true)
  force_customer_storage_for_profiler = lookup(each.value, "force_customer_storage_for_profiler", false)

  # Web Tests
  web_tests = lookup(each.value, "web_tests", [])

  # API Keys
  api_keys = lookup(each.value, "api_keys", [])

  # Smart Detection Rules
  smart_detection_rules = lookup(each.value, "smart_detection_rules", [])

  # Tags
  tags = merge(var.tags, lookup(each.value, "tags", {}))
}

# Call the Diagnostic Settings module - Create multiple diagnostic settings using for_each
module "diagnostic_settings" {
  source   = "../../modules/monitoring/DiagnosticSettings"
  for_each = var.diagnostic_settings

  # Explicit dependencies: Wait for all referenced modules
  depends_on = [
    module.log_analytics_workspace,
    module.virtual_machine,
    module.app_service
  ]

  # Diagnostic Settings Configuration
  # Build the diagnostic settings list with proper resource references
  diagnostic_settings = [{
    name = each.value.name

    # Determine target_resource_id: Priority: target_resource_key > target_resource_id
    # If target_resource_key is provided, automatically detect resource type (VM or App Service)
    target_resource_id = lookup(each.value, "target_resource_key", null) != null ? (
      # If explicit type is provided, use it directly
      lookup(each.value, "target_resource_type", null) == "vm" && length(module.virtual_machine) > 0 && contains(keys(module.virtual_machine), each.value.target_resource_key) ? (
        module.virtual_machine[each.value.target_resource_key].vm_id
        ) : (
        lookup(each.value, "target_resource_type", null) == "app_service" && length(module.app_service) > 0 && contains(keys(module.app_service), each.value.target_resource_key) ? (
          module.app_service[each.value.target_resource_key].app_service_id
          ) : (
          # Auto-detect: Try VM first, then App Service
          length(module.virtual_machine) > 0 && contains(keys(module.virtual_machine), each.value.target_resource_key) ? (
            module.virtual_machine[each.value.target_resource_key].vm_id
            ) : (
            length(module.app_service) > 0 && contains(keys(module.app_service), each.value.target_resource_key) ? (
              module.app_service[each.value.target_resource_key].app_service_id
              ) : (
              lookup(each.value, "target_resource_id", null)
            )
          )
        )
      )
      ) : (
      # Use direct resource ID if no key provided
      lookup(each.value, "target_resource_id", null)
    )

    # Determine log_analytics_workspace_id: Priority: log_analytics_workspace_key > log_analytics_workspace_id
    log_analytics_workspace_id = each.value.log_analytics_workspace_key != null && length(module.log_analytics_workspace) > 0 && contains(keys(module.log_analytics_workspace), each.value.log_analytics_workspace_key) ? (
      module.log_analytics_workspace[each.value.log_analytics_workspace_key].log_analytics_workspace_id
      ) : (
      lookup(each.value, "log_analytics_workspace_id", null)
    )

    eventhub_name                  = lookup(each.value, "eventhub_name", null)
    eventhub_authorization_rule_id = lookup(each.value, "eventhub_authorization_rule_id", null)
    storage_account_id             = lookup(each.value, "storage_account_id", null)
    partner_solution_id            = lookup(each.value, "partner_solution_id", null)

    log_categories    = lookup(each.value, "log_categories", [])
    metric_categories = lookup(each.value, "metric_categories", [])
    legacy_logs       = lookup(each.value, "legacy_logs", [])
    legacy_metrics    = lookup(each.value, "legacy_metrics", [])
  }]
}
