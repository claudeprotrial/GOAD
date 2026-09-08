variable "location" {
  type    = string
  default = "{{config.get_value('azure', 'az_location', 'denmarkeast')}}"
}

# default size : 2cpu / 8GB (B2s v1 unavailable on many subscriptions)
variable "size" {
  type    = string
  default = "Standard_B2s_v2"
}

variable "username" {
  type    = string
  default = "goadmin"
}

variable "password" {
  description = "Password of the windows virtual machine admin user"
  type    = string
  default = "goadmin"
}

variable "jumpbox_username" {
  type    = string
  default = "goad"
}

# Source IP allowed to reach the jumpbox over SSH.
# GOAD is an intentionally vulnerable lab - never leave this as "*".
variable "allowed_source_ip" {
  description = "CIDR allowed to SSH to the jumpbox"
  type    = string
  default = "{{config.get_value('azure', 'az_allowed_source_ip', '*')}}"
}

# Azure Bastion (see bastion.tf). Off by default because Bastion bills hourly
# for as long as it exists and cannot be deallocated like a VM.
variable "enable_bastion" {
  description = "Deploy an Azure Bastion host for reaching the lab VMs"
  type    = bool
  default = {{ 'true' if config.get_value('azure', 'az_enable_bastion', 'no') in ['yes','true','1'] else 'false' }}
}

# Second VNet address space, used only when enable_bastion is true: the lab
# subnet already takes the whole {{ip_range}}.0/24, so there is no room for
# AzureBastionSubnet inside it. Keep this clear of every lab's ip_range.
variable "bastion_address_space" {
  description = "Extra VNet address space carved out for AzureBastionSubnet"
  type    = string
  default = "{{config.get_value('azure', 'az_bastion_address_space', '192.168.250.0/24')}}"
}

variable "bastion_subnet_prefix" {
  description = "Prefix for AzureBastionSubnet, must be /26 or larger"
  type    = string
  default = "{{config.get_value('azure', 'az_bastion_subnet_prefix', '192.168.250.0/26')}}"
}

variable "bastion_sku" {
  description = "Bastion SKU (Basic or Standard; Standard adds native client and scaling)"
  type    = string
  default = "{{config.get_value('azure', 'az_bastion_sku', 'Basic')}}"
}

# OS disk tier for the windows lab VMs.
# Standard_LRS is a spinning HDD (~500 IOPS): SQL Server and the MECM
# install thrash it badly and steps time out. Premium_LRS is SSD-backed.
variable "os_disk_type" {
  description = "Storage account type for the windows VM OS disks"
  type    = string
  default = "Premium_LRS"
}
