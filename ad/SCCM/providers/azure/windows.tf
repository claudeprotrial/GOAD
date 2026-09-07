# Sizing for the SCCM lab (Azure, denmarkeast).
# Standard_B2s_v2 : 2 CPU / 8GB  - burstable, fine for the DC and the client
# Standard_D4s_v5 : 4 CPU / 16GB - non-burstable; MECM site server and the SQL
#                                  backend need sustained CPU through the ~2.5h
#                                  install, where B-series credits run out.
"dc01" = {
  name               = "dc01"
  publisher          = "MicrosoftWindowsServer"
  offer              = "WindowsServer"
  windows_sku        = "2019-Datacenter"
  windows_version    = "latest"
  private_ip_address = "{{ip_range}}.10"
  password           = "AZERTY*qsdfg"
  size               = "Standard_B2s_v2"
}
"srv01" = {
  name               = "srv01"
  publisher          = "MicrosoftWindowsServer"
  offer              = "WindowsServer"
  windows_sku        = "2019-Datacenter"
  windows_version    = "latest"
  private_ip_address = "{{ip_range}}.11"
  password           = "NgtI75cKV+Pu"
  size               = "Standard_D4s_v5"
}
"srv02" = {
  name               = "srv02"
  publisher          = "MicrosoftWindowsServer"
  offer              = "WindowsServer"
  windows_sku        = "2019-Datacenter"
  windows_version    = "latest"
  private_ip_address = "{{ip_range}}.12"
  password           = "NgtazecKV+Pu"
  size               = "Standard_D4s_v5"
}
"ws01" = {
  name               = "ws01"
  publisher          = "MicrosoftWindowsServer"
  offer              = "WindowsServer"
  windows_sku        = "2019-Datacenter"
  windows_version    = "latest"
  private_ip_address = "{{ip_range}}.13"
  password           = "EP+xh7Rk6j90"
  size               = "Standard_B2s_v2"
}