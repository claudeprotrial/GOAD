# ---------------------------------------------------------------------------
# Optional Azure Bastion for reaching the lab.
#
# Off by default (enable_bastion = false): Bastion bills hourly for as long as
# it exists and, unlike a VM, cannot be deallocated - you delete it to stop the
# charge. Nobody should get that bill by accident from a lab template.
#
# Why it is worth having anyway:
#
#   * It needs no inbound rule on the lab subnet. Bastion reaches the VMs from
#     AzureBastionSubnet over the VNet, which the undeletable default rule
#     AllowVnetInBound (priority 65000) already permits. In subscriptions whose
#     governance strips custom NSG rules - observed on MCAPS-managed
#     subscriptions, where the lab NSG is repeatedly found with zero rules -
#     Bastion keeps working while an IP allowlist does not.
#   * It does not depend on knowing the operator's public IP, so it survives a
#     dynamic/roaming client address.
#   * It gives RDP straight to the windows hosts instead of tunnelling
#     everything through the jumpbox, which matters for console work such as
#     the MECM console.
#
# AzureBastionSubnet must be named exactly that and be /26 or larger, and its
# public IP must be Standard SKU with static allocation.
# ---------------------------------------------------------------------------

resource "azurerm_subnet" "bastion_subnet" {
  count                = var.enable_bastion ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = [var.bastion_subnet_prefix]
}

resource "azurerm_public_ip" "bastion_public_ip" {
  count               = var.enable_bastion ? 1 : 0
  name                = "{{lab_name}}-bastion-pip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"

  lifecycle {
    # Same server-assigned ip_tags problem as the other public IPs here.
    ignore_changes = [ip_tags]
  }
}

resource "azurerm_bastion_host" "bastion" {
  count               = var.enable_bastion ? 1 : 0
  name                = "{{lab_name}}-bastion"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = var.bastion_sku

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet[0].id
    public_ip_address_id = azurerm_public_ip.bastion_public_ip[0].id
  }
}
