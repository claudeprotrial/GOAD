# Standard_B2s_v2  : 2 CPU / 8GB   (B2s v1 is NotAvailableForSubscription on many subs)
# Standard_B4s_v2  : 4 CPU / 16GB
# Standard_B2as_v2 : 2 CPU / 8GB   (AMD variant)
"dc01" = {
  name               = "dc01"
  publisher          = "MicrosoftWindowsServer"
  offer              = "WindowsServer"
  windows_sku        = "2019-Datacenter"
  windows_version    = "latest"
  private_ip_address = "{{ip_range}}.10"
  password           = "8dCT-DJjgScp"
  size               = "Standard_B2s_v2"
}
"dc02" = {
  name               = "dc02"
  publisher          = "MicrosoftWindowsServer"
  offer              = "WindowsServer"
  windows_sku        = "2019-Datacenter"
  windows_version    = "latest"
  private_ip_address = "{{ip_range}}.11"
  password           = "NgtI75cKV+Pu"
  size               = "Standard_B2s_v2"
}
"dc03" = {
  name               = "dc03"
  publisher          = "MicrosoftWindowsServer"
  offer              = "WindowsServer"
  windows_sku        = "2016-Datacenter"
  windows_version    = "latest"
  private_ip_address = "{{ip_range}}.12"
  password           = "Ufe-bVXSx9rk"
  size               = "Standard_B2s_v2"
}
"srv02" = {
  name               = "srv02"
  publisher          = "MicrosoftWindowsServer"
  offer              = "WindowsServer"
  windows_sku        = "2019-Datacenter"
  windows_version    = "latest"
  private_ip_address = "{{ip_range}}.22"
  password           = "NgtI75cKV+Pu"
  size               = "Standard_B2s_v2"
}
"srv03" = {
  name               = "srv03"
  publisher          = "MicrosoftWindowsServer"
  offer              = "WindowsServer"
  windows_sku        = "2016-Datacenter"
  windows_version    = "latest"
  private_ip_address = "{{ip_range}}.23"
  password           = "978i2pF43UJ-"
  size               = "Standard_B2s_v2"
}
