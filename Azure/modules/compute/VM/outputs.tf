# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = var.location
}

# Virtual Machine Outputs
output "vm_id" {
  description = "ID of the virtual machine"
  value       = var.vm_os_type == "Linux" ? azurerm_linux_virtual_machine.vm[0].id : azurerm_windows_virtual_machine.vm[0].id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = var.vm_name
}

output "vm_size" {
  description = "Size of the virtual machine"
  value       = var.vm_size
}

output "vm_public_ip" {
  description = "Public IP address of the virtual machine"
  value       = var.enable_public_ip ? azurerm_public_ip.vm_public_ip[0].ip_address : null
}

output "vm_private_ip" {
  description = "Private IP address of the virtual machine"
  value       = azurerm_network_interface.vm_nic.private_ip_address
}

# Network Interface Outputs
output "network_interface_id" {
  description = "ID of the network interface"
  value       = azurerm_network_interface.vm_nic.id
}

output "network_interface_name" {
  description = "Name of the network interface"
  value       = azurerm_network_interface.vm_nic.name
}

# Subnet Output
output "subnet_id" {
  description = "ID of the subnet used by the VM"
  value       = var.subnet_id
}

# Network Security Group Outputs
output "network_security_group_id" {
  description = "ID of the network security group attached to the NIC"
  value       = var.network_security_group_id != null ? var.network_security_group_id : (var.create_network_security_group ? azurerm_network_security_group.vm_nsg[0].id : null)
}

# Data Disks Outputs
output "data_disk_ids" {
  description = "IDs of the data disks"
  value       = azurerm_managed_disk.vm_data_disk[*].id
}

# Connection Information
output "ssh_connection_command" {
  description = "SSH connection command for Linux VM"
  value       = var.vm_os_type == "Linux" && var.enable_public_ip ? "ssh ${var.admin_username}@${azurerm_public_ip.vm_public_ip[0].ip_address}" : null
}

output "rdp_connection_command" {
  description = "RDP connection information for Windows VM"
  value       = var.vm_os_type == "Windows" && var.enable_public_ip ? "mstsc /v:${azurerm_public_ip.vm_public_ip[0].ip_address}" : null
}
