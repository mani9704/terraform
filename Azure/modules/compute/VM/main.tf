# Create Resource Group (if not provided)
resource "azurerm_resource_group" "vm_rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Create Network Security Group (optional, if not using existing NSG)
resource "azurerm_network_security_group" "vm_nsg" {
  count               = var.create_network_security_group && var.network_security_group_id == null ? 1 : 0
  name                = "${var.vm_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  dynamic "security_rule" {
    for_each = var.nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = lookup(security_rule.value, "source_port_range", "*")
      destination_port_range     = lookup(security_rule.value, "destination_port_range", "*")
      source_address_prefix      = lookup(security_rule.value, "source_address_prefix", "*")
      destination_address_prefix = lookup(security_rule.value, "destination_address_prefix", "*")
    }
  }
}

# Create Public IP (if enabled)
resource "azurerm_public_ip" "vm_public_ip" {
  count               = var.enable_public_ip ? 1 : 0
  name                = "${var.vm_name}-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
  tags                = var.tags
}

# Create Network Interface
# DEPENDENCY: Depends on Subnet (via subnet_id reference) and Public IP (if enabled)
# The subnet_id reference creates implicit dependency on Subnet
# The public_ip_address_id reference creates implicit dependency on Public IP
resource "azurerm_network_interface" "vm_nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "${var.vm_name}-ipconfig"
    subnet_id                     = var.subnet_id # Implicit dependency: Subnet must exist before creating NIC
    private_ip_address_allocation = var.private_ip_address_allocation
    private_ip_address            = var.private_ip_address
    public_ip_address_id          = var.enable_public_ip ? azurerm_public_ip.vm_public_ip[0].id : null # Implicit dependency: Public IP must exist if enabled
  }
}

# Create Network Interface Security Group Association
resource "azurerm_network_interface_security_group_association" "vm_nic_nsg" {
  count                     = var.network_security_group_id != null || var.create_network_security_group ? 1 : 0
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = var.network_security_group_id != null ? var.network_security_group_id : azurerm_network_security_group.vm_nsg[0].id
}

# Create Virtual Machine
# DEPENDENCY: Depends on Network Interface (which depends on Subnet)
# Order: VNet → Subnet → NIC → VM
resource "azurerm_linux_virtual_machine" "vm" {
  count                           = var.vm_os_type == "Linux" ? 1 : 0
  name                            = var.vm_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = var.disable_password_authentication
  network_interface_ids           = [azurerm_network_interface.vm_nic.id] # NIC must exist before VM
  tags                            = var.tags

  depends_on = [azurerm_network_interface.vm_nic]

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.source_image_publisher
    offer     = var.source_image_offer
    sku       = var.source_image_sku
    version   = var.source_image_version
  }

  dynamic "admin_ssh_key" {
    for_each = var.disable_password_authentication && var.ssh_public_key != null ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.ssh_public_key
    }
  }

  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_storage_account_uri
  }

  identity {
    type = var.identity_type
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  count                 = var.vm_os_type == "Windows" ? 1 : 0
  name                  = var.vm_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.vm_nic.id] # NIC must exist before VM
  tags                  = var.tags

  depends_on = [azurerm_network_interface.vm_nic]

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.source_image_publisher
    offer     = var.source_image_offer
    sku       = var.source_image_sku
    version   = var.source_image_version
  }

  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_storage_account_uri
  }

  identity {
    type = var.identity_type
  }
}

# Create Data Disks (if specified)
resource "azurerm_managed_disk" "vm_data_disk" {
  count                = length(var.data_disks)
  name                 = "${var.vm_name}-datadisk-${count.index + 1}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.data_disks[count.index].storage_account_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disks[count.index].disk_size_gb
  tags                 = var.tags
}

# Attach Data Disks to VM
# DEPENDENCY: Depends on both Data Disks and VM
resource "azurerm_virtual_machine_data_disk_attachment" "vm_data_disk_attach" {
  count              = length(var.data_disks)
  managed_disk_id    = azurerm_managed_disk.vm_data_disk[count.index].id
  virtual_machine_id = var.vm_os_type == "Linux" ? azurerm_linux_virtual_machine.vm[0].id : azurerm_windows_virtual_machine.vm[0].id
  lun                = count.index + 10
  caching            = var.data_disks[count.index].caching
}
