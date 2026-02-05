# Create Resource Group (if not provided)
resource "azurerm_resource_group" "vnet_rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create Virtual Network
# DEPENDENCY: This must be created FIRST before subnets
resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_servers         = var.dns_servers
  tags                = var.tags
}

# Create Subnets
# DEPENDENCY: Depends on VNet (via virtual_network_name reference)
# This ensures subnets are created AFTER VNet is created
resource "azurerm_subnet" "subnets" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  depends_on = [azurerm_virtual_network.vnet]

  name                                           = each.value.name
  resource_group_name                            = var.resource_group_name
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  address_prefixes                               = each.value.address_prefixes
  service_endpoints                              = lookup(each.value, "service_endpoints", null)
  service_endpoint_policy_ids                    = lookup(each.value, "service_endpoint_policy_ids", null)
  private_endpoint_network_policies_enabled      = lookup(each.value, "private_endpoint_network_policies_enabled", null)
  private_link_service_network_policies_enabled  = lookup(each.value, "private_link_service_network_policies_enabled", null)
  delegation                                      = lookup(each.value, "delegation", null)
}

# Create Network Security Groups (optional, one per subnet)
resource "azurerm_network_security_group" "nsgs" {
  for_each = var.create_nsgs ? {
    for subnet in var.subnets : subnet.name => subnet
    if lookup(subnet, "create_nsg", false)
  } : {}

  name                = "${var.virtual_network_name}-${each.key}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(var.tags, lookup(each.value, "nsg_tags", {}))

  dynamic "security_rule" {
    for_each = lookup(each.value, "nsg_rules", [])
    content {
      name                                       = security_rule.value.name
      priority                                   = security_rule.value.priority
      direction                                  = security_rule.value.direction
      access                                     = security_rule.value.access
      protocol                                   = security_rule.value.protocol
      source_port_range                          = lookup(security_rule.value, "source_port_range", null)
      source_port_ranges                         = lookup(security_rule.value, "source_port_ranges", null)
      destination_port_range                     = lookup(security_rule.value, "destination_port_range", null)
      destination_port_ranges                    = lookup(security_rule.value, "destination_port_ranges", null)
      source_address_prefix                      = lookup(security_rule.value, "source_address_prefix", null)
      source_address_prefixes                    = lookup(security_rule.value, "source_address_prefixes", null)
      destination_address_prefix                 = lookup(security_rule.value, "destination_address_prefix", null)
      destination_address_prefixes               = lookup(security_rule.value, "destination_address_prefixes", null)
      source_application_security_group_ids      = lookup(security_rule.value, "source_application_security_group_ids", null)
      destination_application_security_group_ids = lookup(security_rule.value, "destination_application_security_group_ids", null)
    }
  }
}

# Associate NSGs with Subnets
# DEPENDENCY: Depends on both Subnets and NSGs
resource "azurerm_subnet_network_security_group_association" "subnet_nsg_assoc" {
  for_each = var.create_nsgs ? {
    for subnet in var.subnets : subnet.name => subnet
    if lookup(subnet, "create_nsg", false)
  } : {}

  depends_on = [
    azurerm_subnet.subnets,
    azurerm_network_security_group.nsgs
  ]

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.nsgs[each.key].id
}
