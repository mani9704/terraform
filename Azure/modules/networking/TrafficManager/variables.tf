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

# Traffic Manager Profile Variables
variable "traffic_manager_name" {
  description = "Name of the Traffic Manager profile"
  type        = string
}

variable "traffic_routing_method" {
  description = "The routing method used by the Traffic Manager profile (Priority, Weighted, Performance, Geographic, Subnet, MultiValue)"
  type        = string
  default     = "Performance"
  validation {
    condition     = contains(["Priority", "Weighted", "Performance", "Geographic", "Subnet", "MultiValue"], var.traffic_routing_method)
    error_message = "traffic_routing_method must be one of: Priority, Weighted, Performance, Geographic, Subnet, MultiValue."
  }
}

variable "relative_dns_name" {
  description = "The relative DNS name of the Traffic Manager profile"
  type        = string
}

variable "ttl" {
  description = "The TTL value of the Traffic Manager profile DNS record"
  type        = number
  default     = 300
}

# Monitor Configuration
variable "monitor_config" {
  description = "Monitor configuration for health checks"
  type = object({
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
  })
  default = {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 3
    expected_status_code_ranges  = ["200"]
    custom_headers               = []
  }
}

# Endpoints
variable "endpoints" {
  description = "List of endpoints for the Traffic Manager profile"
  type = list(object({
    name     = string
    type     = string # "azure", "external", or "nested"
    enabled  = optional(bool, true)
    weight   = optional(number, 1)
    priority = optional(number, null)

    # For Azure endpoints
    target_resource_id = optional(string, null)

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
  }))
  default = []
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
