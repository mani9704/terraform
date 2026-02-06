# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}

output "resource_group_id" {
  description = "ID of the resource group (if created)"
  value       = var.create_resource_group ? azurerm_resource_group.fd_rg[0].id : null
}

# Front Door Profile Outputs
output "front_door_profile_id" {
  description = "ID of the Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.fd_profile.id
}

output "front_door_profile_name" {
  description = "Name of the Front Door profile"
  value       = azurerm_cdn_frontdoor_profile.fd_profile.name
}

# Front Door Endpoint Outputs
output "front_door_endpoint_id" {
  description = "ID of the Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.fd_endpoint.id
}

output "front_door_endpoint_name" {
  description = "Name of the Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.fd_endpoint.name
}

output "front_door_endpoint_host_name" {
  description = "Hostname of the Front Door endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.fd_endpoint.host_name
}

# Origin Groups Outputs
output "origin_group_ids" {
  description = "Map of origin group names to their IDs"
  value       = { for k, v in azurerm_cdn_frontdoor_origin_group.fd_origin_groups : k => v.id }
}

# Origins Outputs
output "origin_ids" {
  description = "Map of origin names to their IDs"
  value       = { for k, v in azurerm_cdn_frontdoor_origin.fd_origins : k => v.id }
}

# Custom Domains Outputs
output "custom_domain_ids" {
  description = "Map of custom domain hostnames to their IDs"
  value       = { for k, v in azurerm_cdn_frontdoor_custom_domain.fd_custom_domains : k => v.id }
}

output "custom_domain_validation_tokens" {
  description = "Map of custom domain hostnames to their validation tokens"
  value       = { for k, v in azurerm_cdn_frontdoor_custom_domain.fd_custom_domains : k => v.validation_token }
}

# Routes Outputs
output "route_ids" {
  description = "Map of route names to their IDs"
  value       = { for k, v in azurerm_cdn_frontdoor_route.fd_routes : k => v.id }
}

# Rule Sets Outputs
output "rule_set_ids" {
  description = "Map of rule set names to their IDs"
  value       = { for k, v in azurerm_cdn_frontdoor_rule_set.fd_rule_sets : k => v.id }
}

# Security Policy Outputs
output "security_policy_ids" {
  description = "Map of security policy names to their IDs"
  value       = { for k, v in azurerm_cdn_frontdoor_security_policy.fd_security_policies : k => v.id }
}

output "security_policy_id" {
  description = "[DEPRECATED] ID of the first security policy (for backward compatibility)"
  value       = length(azurerm_cdn_frontdoor_security_policy.fd_security_policies) > 0 ? values(azurerm_cdn_frontdoor_security_policy.fd_security_policies)[0].id : (var.waf_policy_id != null && length(azurerm_cdn_frontdoor_security_policy.fd_security_policy_legacy) > 0 ? azurerm_cdn_frontdoor_security_policy.fd_security_policy_legacy[0].id : null)
}

# Front Door URL
output "front_door_url" {
  description = "Front Door endpoint URL"
  value       = "https://${azurerm_cdn_frontdoor_endpoint.fd_endpoint.host_name}"
}
