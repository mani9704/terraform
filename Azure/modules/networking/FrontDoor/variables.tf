# Resource Group Variables
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "create_resource_group" {
  description = "Whether to create a new resource group"
  type        = bool
  default     = false
}

variable "location" {
  description = "Azure region where resources will be created (used only if creating resource group)"
  type        = string
  default     = "global"
}

# Front Door Profile Variables
variable "front_door_profile_name" {
  description = "Name of the Front Door profile"
  type        = string
}

variable "sku_name" {
  description = "SKU name for Front Door profile (Standard_AzureFrontDoor or Premium_AzureFrontDoor)"
  type        = string
  default     = "Standard_AzureFrontDoor"
  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.sku_name)
    error_message = "sku_name must be either 'Standard_AzureFrontDoor' or 'Premium_AzureFrontDoor'."
  }
}

variable "response_timeout_seconds" {
  description = "The response timeout in seconds for the Front Door profile"
  type        = number
  default     = 60
}

# Front Door Endpoint Variables
variable "front_door_endpoint_name" {
  description = "Name of the Front Door endpoint"
  type        = string
}

variable "endpoint_enabled" {
  description = "Whether the Front Door endpoint is enabled"
  type        = bool
  default     = true
}

# Origin Groups Variables
variable "origin_groups" {
  description = "List of origin groups (backend pools) for the Front Door"
  type = list(object({
    name                                                      = string
    session_affinity_enabled                                  = optional(bool, false)
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
  }))
  default = []
}

# Origins Variables
variable "origins" {
  description = "List of origins (backends) for the Front Door. Can be Azure App Services, VMs, or external endpoints."
  type = list(object({
    name                           = string
    origin_group_name              = string
    host_name                      = string # App Service default hostname, VM public IP, or external host
    http_port                      = optional(number, 80)
    https_port                     = optional(number, 443)
    origin_host_header             = optional(string, null)
    priority                       = optional(number, 1)
    weight                         = optional(number, 1000)
    enabled                        = optional(bool, true)
    certificate_name_check_enabled = optional(bool, true)
    private_link = optional(object({
      location               = string
      private_link_target_id = string
      request_message        = optional(string, "Please approve")
      target_type            = optional(string, null)
    }), null)
  }))
  default = []
}

# Custom Domains Variables
variable "custom_domains" {
  description = "List of custom domains for the Front Door"
  type = list(object({
    name        = string
    host_name   = string
    dns_zone_id = optional(string, null)
    tls = optional(object({
      certificate_type        = string
      minimum_tls_version     = optional(string, "TLS12")
      cdn_frontdoor_secret_id = optional(string, null)
    }), null)
  }))
  default = []
}

# Security Policies Variables (Multiple WAF Policies Support)
variable "security_policies" {
  description = "List of security policies (WAF policies) to associate with Front Door. Each policy can have multiple associations."
  type = list(object({
    name          = string
    waf_policy_id = string # Resource ID of the WAF policy
    associations = list(object({
      custom_domain_names = optional(list(string), [])     # List of custom domain names to associate
      patterns_to_match   = optional(list(string), ["/*"]) # URL patterns to match
    }))
  }))
  default = []
}

# Legacy WAF Policy Variables (kept for backward compatibility)
variable "waf_policy_id" {
  description = "[DEPRECATED] Use security_policies instead. Resource ID of the WAF policy to associate with Front Door (optional)"
  type        = string
  default     = null
}

variable "waf_patterns_to_match" {
  description = "[DEPRECATED] Use security_policies instead. List of patterns to match for WAF policy association"
  type        = list(string)
  default     = ["/*"]
}

# Routes Variables
variable "routes" {
  description = "List of routes (routing rules) for the Front Door"
  type = list(object({
    name                   = string
    origin_group_name      = string
    origin_names           = list(string)
    enabled                = optional(bool, true)
    forwarding_protocol    = optional(string, "MatchRequest")
    https_redirect_enabled = optional(bool, false)
    patterns_to_match      = optional(list(string), ["/*"])
    supported_protocols    = optional(list(string), ["Http", "Https"])
    custom_domain_names    = optional(list(string), null)
    cache = optional(object({
      query_string_caching_behavior = optional(string, "IgnoreQueryString")
      query_strings                 = optional(list(string), null)
      compression_enabled           = optional(bool, true)
      content_types_to_compress = optional(list(string), [
        "text/html", "text/plain", "text/css", "text/javascript",
        "application/x-javascript", "application/javascript",
        "application/json", "application/xml"
      ])
    }), null)
  }))
  default = []
}

# Rule Sets Variables
variable "rule_sets" {
  description = "List of rule sets for the Front Door (optional)"
  type = list(object({
    name = string
  }))
  default = []
}

# Rules Variables
variable "rules" {
  description = "List of rules for the Front Door (optional)"
  type = list(object({
    name              = string
    rule_set_name     = string
    order             = optional(number, 1)
    behavior_on_match = optional(string, "Continue")
    conditions = optional(list(object({
      request_header = optional(object({
        header_name        = string
        operator           = string
        match_values       = optional(list(string), [])
        transform          = optional(list(string), [])
        negation_condition = optional(bool, false)
      }), null)
      request_method = optional(object({
        operator           = string
        match_values       = optional(list(string), [])
        negation_condition = optional(bool, false)
      }), null)
      request_uri = optional(object({
        operator           = string
        match_values       = optional(list(string), [])
        transform          = optional(list(string), [])
        negation_condition = optional(bool, false)
      }), null)
      query_string = optional(object({
        operator           = string
        match_values       = optional(list(string), [])
        transform          = optional(list(string), [])
        negation_condition = optional(bool, false)
      }), null)
      remote_address = optional(object({
        operator           = string
        match_values       = optional(list(string), [])
        negation_condition = optional(bool, false)
      }), null)
      request_body = optional(object({
        operator           = string
        match_values       = optional(list(string), [])
        transform          = optional(list(string), [])
        negation_condition = optional(bool, false)
      }), null)
    })), [])
    actions = optional(list(object({
      route_configuration_override = optional(object({
        origin_group_name             = optional(string, null)
        forwarding_protocol           = optional(string, null)
        query_string_caching_behavior = optional(string, null)
        compression_enabled           = optional(bool, null)
        cache_behavior                = optional(string, null)
        cache_duration                = optional(string, null)
      }), null)
      url_redirect = optional(object({
        redirect_type        = string
        destination_path     = optional(string, null)
        destination_hostname = optional(string, null)
        destination_fragment = optional(string, null)
        query_string         = optional(string, null)
        redirect_protocol    = optional(string, "MatchRequest")
      }), null)
      url_rewrite = optional(object({
        source_pattern          = string
        destination             = string
        preserve_unmatched_path = optional(bool, false)
      }), null)
      request_header = optional(object({
        header_action = string
        header_name   = string
        value         = optional(string, null)
      }), null)
      response_header = optional(object({
        header_action = string
        header_name   = string
        value         = optional(string, null)
      }), null)
    })), [])
  }))
  default = []
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
