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
  description = "Azure region where resources will be created"
  type        = string
}

# Virtual Machine Variables
variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B1s"
}

variable "vm_os_type" {
  description = "Operating system type (Linux or Windows)"
  type        = string
  default     = "Linux"
  validation {
    condition     = contains(["Linux", "Windows"], var.vm_os_type)
    error_message = "vm_os_type must be either 'Linux' or 'Windows'."
  }
}

# Admin Credentials
variable "admin_username" {
  description = "Administrator username for the VM"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Administrator password for the VM (required for Windows, optional for Linux if SSH key is provided)"
  type        = string
  sensitive   = true
  default     = null
}

variable "ssh_public_key" {
  description = "SSH public key for Linux VM authentication"
  type        = string
  default     = null
  sensitive   = true
}

variable "disable_password_authentication" {
  description = "Disable password authentication for Linux VM (use SSH keys instead)"
  type        = bool
  default     = true
}

# Network Variables
variable "subnet_id" {
  description = "ID of the subnet where the VM will be deployed"
  type        = string
}

variable "enable_public_ip" {
  description = "Enable public IP for the VM"
  type        = bool
  default     = true
}

variable "public_ip_allocation_method" {
  description = "Allocation method for public IP (Static or Dynamic)"
  type        = string
  default     = "Static"
}

variable "public_ip_sku" {
  description = "SKU for public IP (Basic or Standard)"
  type        = string
  default     = "Basic"
}

variable "private_ip_address_allocation" {
  description = "Allocation method for private IP (Static or Dynamic)"
  type        = string
  default     = "Dynamic"
}

variable "private_ip_address" {
  description = "Static private IP address (used when private_ip_address_allocation is Static)"
  type        = string
  default     = null
}

# Network Security Group Variables
variable "network_security_group_id" {
  description = "ID of an existing network security group to attach to the NIC (optional)"
  type        = string
  default     = null
}

variable "create_network_security_group" {
  description = "Whether to create a new network security group (only used if network_security_group_id is not provided)"
  type        = bool
  default     = false
}

variable "nsg_rules" {
  description = "List of network security group rules"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = optional(string, "*")
    destination_port_range     = optional(string, "*")
    source_address_prefix      = optional(string, "*")
    destination_address_prefix = optional(string, "*")
  }))
  default = [
    {
      name                       = "SSH"
      priority                   = 1001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_range     = "22"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
}

# OS Disk Variables
variable "os_disk_caching" {
  description = "Caching type for OS disk (None, ReadOnly, ReadWrite)"
  type        = string
  default     = "ReadWrite"
}

variable "os_disk_storage_account_type" {
  description = "Storage account type for OS disk (Standard_LRS, StandardSSD_LRS, Premium_LRS)"
  type        = string
  default     = "StandardSSD_LRS"
}

variable "os_disk_size_gb" {
  description = "Size of OS disk in GB"
  type        = number
  default     = 30
}

# Source Image Variables
variable "source_image_publisher" {
  description = "Publisher of the source image"
  type        = string
  default     = "Canonical"
}

variable "source_image_offer" {
  description = "Offer of the source image"
  type        = string
  default     = "0001-com-ubuntu-server-jammy"
}

variable "source_image_sku" {
  description = "SKU of the source image"
  type        = string
  default     = "22_04-lts"
}

variable "source_image_version" {
  description = "Version of the source image"
  type        = string
  default     = "latest"
}

# Data Disks Variables
variable "data_disks" {
  description = "List of data disks to attach to the VM"
  type = list(object({
    disk_size_gb         = number
    storage_account_type = string
    caching              = string
  }))
  default = []
}

# Boot Diagnostics
variable "boot_diagnostics_storage_account_uri" {
  description = "URI of the storage account for boot diagnostics"
  type        = string
  default     = null
}

# Identity
variable "identity_type" {
  description = "Type of managed identity (SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned)"
  type        = string
  default     = "SystemAssigned"
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
