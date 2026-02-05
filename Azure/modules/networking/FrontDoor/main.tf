# Create Resource Group (if not provided)
resource "azurerm_resource_group" "fd_rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create Front Door Profile
resource "azurerm_cdn_frontdoor_profile" "fd_profile" {
  name                = var.front_door_profile_name
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  response_timeout_seconds = var.response_timeout_seconds
  tags                = var.tags
}

# Create Front Door Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "fd_origin_groups" {
  for_each = { for group in var.origin_groups : group.name => group }

  name                     = each.value.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id

  dynamic "load_balancing" {
    for_each = lookup(each.value, "load_balancing", null) != null ? [each.value.load_balancing] : []
    content {
      additional_latency_in_milliseconds = lookup(load_balancing.value, "additional_latency_in_milliseconds", 50)
      sample_size                        = lookup(load_balancing.value, "sample_size", 4)
      successful_samples_required        = lookup(load_balancing.value, "successful_samples_required", 3)
    }
  }

  dynamic "health_probe" {
    for_each = lookup(each.value, "health_probe", null) != null ? [each.value.health_probe] : []
    content {
      protocol            = lookup(health_probe.value, "protocol", "Http")
      request_type        = lookup(health_probe.value, "request_type", "HEAD")
      interval_in_seconds = lookup(health_probe.value, "interval_in_seconds", 100)
      path                = lookup(health_probe.value, "path", "/")
    }
  }

  session_affinity_enabled = lookup(each.value, "session_affinity_enabled", false)
  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = lookup(each.value, "restore_traffic_time_to_healed_or_new_endpoint_in_minutes", 10)
}

# Create Front Door Origin
resource "azurerm_cdn_frontdoor_origin" "fd_origins" {
  for_each = { for origin in var.origins : origin.name => origin }

  name                          = each.value.name
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.fd_origin_groups[each.value.origin_group_name].id

  # If target_resource_id (App Service/VM) is provided, use it; otherwise use host_name
  target_resource_id = lookup(each.value, "target_resource_id", null)
  host_name          = lookup(each.value, "target_resource_id", null) == null ? each.value.host_name : null
  
  http_port          = lookup(each.value, "http_port", 80)
  https_port         = lookup(each.value, "https_port", 443)
  origin_host_header = lookup(each.value, "origin_host_header", null)
  priority           = lookup(each.value, "priority", 1)
  weight             = lookup(each.value, "weight", 1000)
  enabled            = lookup(each.value, "enabled", true)

  certificate_name_check_enabled = lookup(each.value, "certificate_name_check_enabled", true)

  dynamic "private_link" {
    for_each = lookup(each.value, "private_link", null) != null ? [each.value.private_link] : []
    content {
      location                  = private_link.value.location
      private_link_target_id    = private_link.value.private_link_target_id
      request_message           = lookup(private_link.value, "request_message", "Please approve")
      target_type               = lookup(private_link.value, "target_type", null)
    }
  }
}

# Create Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "fd_endpoint" {
  name                     = var.front_door_endpoint_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id
  enabled                  = var.endpoint_enabled
  tags                     = var.tags
}

# Create Front Door Custom Domain (Optional)
resource "azurerm_cdn_frontdoor_custom_domain" "fd_custom_domains" {
  for_each = { for domain in var.custom_domains : domain.host_name => domain }

  name                     = each.value.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id
  host_name                = each.value.host_name

  dynamic "tls" {
    for_each = lookup(each.value, "tls", null) != null ? [each.value.tls] : []
    content {
      certificate_type    = tls.value.certificate_type
      minimum_tls_version = lookup(tls.value, "minimum_tls_version", "TLS12")
      cdn_frontdoor_secret_id = lookup(tls.value, "cdn_frontdoor_secret_id", null)
    }
  }

  dns_zone_id = lookup(each.value, "dns_zone_id", null)
}

# Create Front Door Security Policies (WAF Policies)
# Supports multiple security policies, each with different WAF policies and domain associations
resource "azurerm_cdn_frontdoor_security_policy" "fd_security_policies" {
  for_each = {
    for policy in var.security_policies : policy.name => policy
  }

  name                     = each.value.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = each.value.waf_policy_id

      dynamic "association" {
        for_each = each.value.associations
        content {
          domain {
            cdn_frontdoor_domain_id = lookup(association.value, "custom_domain_names", null) != null && length(association.value.custom_domain_names) > 0 ? [
              for domain_name in association.value.custom_domain_names : azurerm_cdn_frontdoor_custom_domain.fd_custom_domains[domain_name].id
            ] : []
          }
          patterns_to_match = lookup(association.value, "patterns_to_match", ["/*"])
        }
      }
    }
  }
}

# Legacy Security Policy (for backward compatibility with old waf_policy_id variable)
resource "azurerm_cdn_frontdoor_security_policy" "fd_security_policy_legacy" {
  count = var.waf_policy_id != null && length(var.security_policies) == 0 ? 1 : 0

  name                     = "${var.front_door_profile_name}-waf-policy-legacy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = var.waf_policy_id

      association {
        domain {
          cdn_frontdoor_domain_id = [for domain in azurerm_cdn_frontdoor_custom_domain.fd_custom_domains : domain.id]
        }
        patterns_to_match = var.waf_patterns_to_match
      }
    }
  }
}

# Create Front Door Route
resource "azurerm_cdn_frontdoor_route" "fd_routes" {
  for_each = { for route in var.routes : route.name => route }

  name                          = each.value.name
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.fd_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.fd_origin_groups[each.value.origin_group_name].id
  cdn_frontdoor_origin_ids      = [for origin_name in each.value.origin_names : azurerm_cdn_frontdoor_origin.fd_origins[origin_name].id]

  enabled                        = lookup(each.value, "enabled", true)
  forwarding_protocol            = lookup(each.value, "forwarding_protocol", "MatchRequest")
  https_redirect_enabled         = lookup(each.value, "https_redirect_enabled", false)
  patterns_to_match              = lookup(each.value, "patterns_to_match", ["/*"])
  supported_protocols            = lookup(each.value, "supported_protocols", ["Http", "Https"])
  cdn_frontdoor_custom_domain_ids = lookup(each.value, "custom_domain_names", null) != null ? [
    for domain_name in each.value.custom_domain_names : azurerm_cdn_frontdoor_custom_domain.fd_custom_domains[domain_name].id
  ] : []

  dynamic "cache" {
    for_each = lookup(each.value, "cache", null) != null ? [each.value.cache] : []
    content {
      query_string_caching_behavior = lookup(cache.value, "query_string_caching_behavior", "IgnoreQueryString")
      query_strings                 = lookup(cache.value, "query_strings", null)
      compression_enabled           = lookup(cache.value, "compression_enabled", true)
      content_types_to_compress     = lookup(cache.value, "content_types_to_compress", ["text/html", "text/plain", "text/css", "text/javascript", "application/x-javascript", "application/javascript", "application/json", "application/xml"])
    }
  }
}

# Create Front Door Rule Set (Optional)
resource "azurerm_cdn_frontdoor_rule_set" "fd_rule_sets" {
  for_each = { for rule_set in var.rule_sets : rule_set.name => rule_set }

  name                     = each.value.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd_profile.id
}

# Create Front Door Rules (Optional)
resource "azurerm_cdn_frontdoor_rule" "fd_rules" {
  for_each = {
    for rule in var.rules : "${rule.rule_set_name}.${rule.name}" => rule
  }

  name                      = each.value.name
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.fd_rule_sets[each.value.rule_set_name].id
  order                     = lookup(each.value, "order", 1)
  behavior_on_match         = lookup(each.value, "behavior_on_match", "Continue")

  dynamic "conditions" {
    for_each = lookup(each.value, "conditions", [])
    content {
      dynamic "request_header" {
        for_each = lookup(conditions.value, "request_header", null) != null ? [conditions.value.request_header] : []
        content {
          header_name = request_header.value.header_name
          operator    = request_header.value.operator
          match_values = lookup(request_header.value, "match_values", [])
          transform   = lookup(request_header.value, "transform", [])
          negation_condition = lookup(request_header.value, "negation_condition", false)
        }
      }

      dynamic "request_method" {
        for_each = lookup(conditions.value, "request_method", null) != null ? [conditions.value.request_method] : []
        content {
          operator    = request_method.value.operator
          match_values = lookup(request_method.value, "match_values", [])
          negation_condition = lookup(request_method.value, "negation_condition", false)
        }
      }

      dynamic "request_uri" {
        for_each = lookup(conditions.value, "request_uri", null) != null ? [conditions.value.request_uri] : []
        content {
          operator    = request_uri.value.operator
          match_values = lookup(request_uri.value, "match_values", [])
          transform   = lookup(request_uri.value, "transform", [])
          negation_condition = lookup(request_uri.value, "negation_condition", false)
        }
      }

      dynamic "query_string" {
        for_each = lookup(conditions.value, "query_string", null) != null ? [conditions.value.query_string] : []
        content {
          operator    = query_string.value.operator
          match_values = lookup(query_string.value, "match_values", [])
          transform   = lookup(query_string.value, "transform", [])
          negation_condition = lookup(query_string.value, "negation_condition", false)
        }
      }

      dynamic "remote_address" {
        for_each = lookup(conditions.value, "remote_address", null) != null ? [conditions.value.remote_address] : []
        content {
          operator    = remote_address.value.operator
          match_values = lookup(remote_address.value, "match_values", [])
          negation_condition = lookup(remote_address.value, "negation_condition", false)
        }
      }

      dynamic "request_body" {
        for_each = lookup(conditions.value, "request_body", null) != null ? [conditions.value.request_body] : []
        content {
          operator    = request_body.value.operator
          match_values = lookup(request_body.value, "match_values", [])
          transform   = lookup(request_body.value, "transform", [])
          match_variable = lookup(request_body.value, "match_variable", null)
          negation_condition = lookup(request_body.value, "negation_condition", false)
        }
      }
    }
  }

  dynamic "actions" {
    for_each = lookup(each.value, "actions", [])
    content {
      dynamic "route_configuration_override_action" {
        for_each = lookup(actions.value, "route_configuration_override", null) != null ? [actions.value.route_configuration_override] : []
        content {
          origin_group_id = route_configuration_override_action.value.origin_group_name != null ? azurerm_cdn_frontdoor_origin_group.fd_origin_groups[route_configuration_override_action.value.origin_group_name].id : null
          forwarding_protocol = lookup(route_configuration_override_action.value, "forwarding_protocol", null)
          query_string_caching_behavior = lookup(route_configuration_override_action.value, "query_string_caching_behavior", null)
          compression_enabled = lookup(route_configuration_override_action.value, "compression_enabled", null)
          cache_behavior = lookup(route_configuration_override_action.value, "cache_behavior", null)
          cache_duration = lookup(route_configuration_override_action.value, "cache_duration", null)
        }
      }

      dynamic "url_redirect_action" {
        for_each = lookup(actions.value, "url_redirect", null) != null ? [actions.value.url_redirect] : []
        content {
          redirect_type        = url_redirect_action.value.redirect_type
          destination_protocol = lookup(url_redirect_action.value, "destination_protocol", "MatchRequest")
          destination_path     = lookup(url_redirect_action.value, "destination_path", null)
          destination_hostname = lookup(url_redirect_action.value, "destination_hostname", null)
          destination_fragment = lookup(url_redirect_action.value, "destination_fragment", null)
          query_string         = lookup(url_redirect_action.value, "query_string", null)
          redirect_protocol    = lookup(url_redirect_action.value, "redirect_protocol", "MatchRequest")
        }
      }

      dynamic "url_rewrite_action" {
        for_each = lookup(actions.value, "url_rewrite", null) != null ? [actions.value.url_rewrite] : []
        content {
          source_pattern      = url_rewrite_action.value.source_pattern
          destination         = url_rewrite_action.value.destination
          preserve_unmatched_path = lookup(url_rewrite_action.value, "preserve_unmatched_path", false)
        }
      }

      dynamic "request_header_action" {
        for_each = lookup(actions.value, "request_header", null) != null ? [actions.value.request_header] : []
        content {
          header_action = request_header_action.value.header_action
          header_name   = request_header_action.value.header_name
          value         = lookup(request_header_action.value, "value", null)
        }
      }

      dynamic "response_header_action" {
        for_each = lookup(actions.value, "response_header", null) != null ? [actions.value.response_header] : []
        content {
          header_action = response_header_action.value.header_action
          header_name   = response_header_action.value.header_name
          value         = lookup(response_header_action.value, "value", null)
          overwrite_if_exists = lookup(response_header_action.value, "overwrite_if_exists", false)
        }
      }
    }
  }
}
