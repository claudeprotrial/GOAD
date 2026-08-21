variable "location" {
  type    = string
  default = "{{config.get_value('azure', 'az_location', 'westus2')}}"
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
