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

# OS disk tier for the windows lab VMs.
# Standard_LRS is a spinning HDD (~500 IOPS): SQL Server and the MECM
# install thrash it badly and steps time out. Premium_LRS is SSD-backed.
variable "os_disk_type" {
  description = "Storage account type for the windows VM OS disks"
  type    = string
  default = "Premium_LRS"
}
