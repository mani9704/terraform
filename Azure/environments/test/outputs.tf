# Virtual Network Outputs (for all VNets)
output "virtual_networks" {
  description = "Map of all virtual networks"
  value = {
    for k, v in module.virtual_network : k => {
      id         = v.virtual_network_id
      name       = v.virtual_network_name
      subnet_ids = v.subnet_ids
      nsg_ids    = v.network_security_group_ids
    }
  }
}

# Virtual Machine Outputs (for all VMs)
output "virtual_machines" {
  description = "Map of all virtual machines"
  value = {
    for k, v in module.virtual_machine : k => {
      id                   = v.vm_id
      name                 = v.vm_name
      public_ip            = v.vm_public_ip
      private_ip           = v.vm_private_ip
      ssh_command          = v.ssh_connection_command
      rdp_command          = v.rdp_connection_command
      network_interface_id = v.network_interface_id
    }
  }
}

# Convenience Outputs (for backward compatibility - shows first VM/VNet)
output "vm_public_ips" {
  description = "Map of VM keys to public IP addresses"
  value = {
    for k, v in module.virtual_machine : k => v.vm_public_ip
  }
}

output "vm_private_ips" {
  description = "Map of VM keys to private IP addresses"
  value = {
    for k, v in module.virtual_machine : k => v.vm_private_ip
  }
}

output "ssh_commands" {
  description = "Map of VM keys to SSH connection commands"
  value = {
    for k, v in module.virtual_machine : k => v.ssh_connection_command
  }
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}

# Traffic Manager Outputs (for all Traffic Managers)
output "traffic_managers" {
  description = "Map of all Traffic Manager profiles"
  value = {
    for k, v in module.traffic_manager : k => {
      id                     = v.traffic_manager_profile_id
      name                   = v.traffic_manager_profile_name
      fqdn                   = v.fqdn
      traffic_routing_method = v.traffic_routing_method
      all_endpoints          = v.all_endpoints
      monitor_config         = v.monitor_config
    }
  }
}

output "traffic_manager_fqdns" {
  description = "Map of Traffic Manager keys to FQDNs"
  value = {
    for k, v in module.traffic_manager : k => v.fqdn
  }
}

# Front Door Outputs (for all Front Doors)
output "front_doors" {
  description = "Map of all Front Door profiles"
  value = {
    for k, v in module.front_door : k => {
      id                 = v.front_door_profile_id
      name               = v.front_door_profile_name
      endpoint_host_name = v.front_door_endpoint_host_name
      front_door_url     = v.front_door_url
      origin_group_ids   = v.origin_group_ids
      origin_ids         = v.origin_ids
      custom_domain_ids  = v.custom_domain_ids
      route_ids          = v.route_ids
    }
  }
}

output "front_door_urls" {
  description = "Map of Front Door keys to URLs"
  value = {
    for k, v in module.front_door : k => v.front_door_url
  }
}

output "front_door_hostnames" {
  description = "Map of Front Door keys to hostnames"
  value = {
    for k, v in module.front_door : k => v.front_door_endpoint_host_name
  }
}

# App Service Outputs (for all App Services)
output "app_services" {
  description = "Map of all App Services"
  value = {
    for k, v in module.app_service : k => {
      id                  = v.app_service_id
      name                = v.app_service_name
      default_host_name   = v.app_service_default_host_name
      app_service_url     = v.app_service_url
      app_service_plan_id = v.app_service_plan_id
      principal_id        = v.app_service_principal_id
    }
  }
}

output "app_service_urls" {
  description = "Map of App Service keys to URLs"
  value = {
    for k, v in module.app_service : k => v.app_service_url
  }
}

output "app_service_hostnames" {
  description = "Map of App Service keys to hostnames"
  value = {
    for k, v in module.app_service : k => v.app_service_default_host_name
  }
}

# Deployment Slots Outputs (for all App Services)
output "app_service_deployment_slots" {
  description = "Map of App Service keys to their deployment slots"
  value = {
    for k, v in module.app_service : k => {
      slot_ids       = v.deployment_slot_ids
      slot_hostnames = v.deployment_slot_hostnames
      slot_urls      = v.deployment_slot_urls
    }
  }
}

# ============================================
# MONITORING OUTPUTS
# ============================================

# Log Analytics Workspace Outputs
output "log_analytics_workspaces" {
  description = "Map of Log Analytics Workspace keys to their details"
  value = {
    for k, v in module.log_analytics_workspace : k => {
      id           = v.log_analytics_workspace_id
      name         = v.log_analytics_workspace_name
      workspace_id = v.log_analytics_workspace_workspace_id
      solution_ids = v.solution_ids
    }
  }
}

# Application Insights Outputs
output "application_insights" {
  description = "Map of Application Insights keys to their details"
  value = {
    for k, v in module.application_insights : k => {
      id                       = v.application_insights_id
      name                     = v.application_insights_name
      app_id                   = v.application_insights_app_id
      instrumentation_key      = v.application_insights_instrumentation_key
      connection_string        = v.application_insights_connection_string
      web_test_ids             = v.web_test_ids
      api_key_ids              = v.api_key_ids
      smart_detection_rule_ids = v.smart_detection_rule_ids
    }
  }
}

# Diagnostic Settings Outputs
output "diagnostic_settings" {
  description = "Map of diagnostic setting keys to their details"
  value = {
    for k, v in module.diagnostic_settings : k => v.diagnostic_settings
  }
}

output "diagnostic_setting_ids" {
  description = "Map of diagnostic setting keys to their IDs"
  value = {
    for k, v in module.diagnostic_settings : k => v.diagnostic_setting_ids
  }
}

# ============================================
# STORAGE ACCOUNT OUTPUTS
# ============================================

output "storage_accounts" {
  description = "Map of Storage Account keys to their details"
  value = {
    for k, v in module.storage_account : k => {
      id                    = v.storage_account_id
      name                  = v.storage_account_name
      primary_location      = v.storage_account_primary_location
      primary_blob_endpoint = v.primary_blob_endpoint
      primary_file_endpoint = v.primary_file_endpoint
      file_share_names      = v.file_share_names
      file_share_ids        = v.file_share_ids
    }
  }
}

output "storage_account_connection_strings" {
  description = "Map of Storage Account keys to their connection strings (sensitive)"
  value = {
    for k, v in module.storage_account : k => {
      primary_connection_string   = v.primary_connection_string
      secondary_connection_string = v.secondary_connection_string
    }
  }
  sensitive = true
}
