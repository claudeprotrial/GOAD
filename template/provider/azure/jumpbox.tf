resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_public_ip" "ubuntu_public_ip" {
  name                = "ubuntu-public-ip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  # Basic SKU public IPs are retired: subscriptions now get a quota of 0 and
  # creation fails with IPv4BasicSkuPublicIpCountLimitReached. Standard SKU
  # requires allocation_method = "Static", which is already set above.
  sku                 = "Standard"
}

resource "azurerm_network_interface" "ubuntu_jumbox_nic" {
  name                = "ubuntu-jumbox-nic"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "ubuntu-jumbox-nic-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "{{ip_range}}.100"
    public_ip_address_id          = azurerm_public_ip.ubuntu_public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                = "ubuntu-jumpbox"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  size                = var.size
  admin_username      = var.jumpbox_username
  network_interface_ids = [
    azurerm_network_interface.ubuntu_jumbox_nic.id,
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.jumpbox_username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

}

# Write the jumpbox private key where the provisioner expects to find it.
#
# This was a local-exec running:
#   echo '<pem>' > ../ssh_keys/ubuntu-jumpbox.pem && chmod 600 ...
# which is a POSIX shell line. On Windows terraform hands it to cmd.exe,
# where the quotes are written literally, the multi-line PEM is mangled and
# chmod does not exist. The provisioner reports no error, so the key silently
# never appears and every later ssh/scp to the jumpbox fails with
# "Permission denied (publickey)" - after the whole lab has been built.
#
# local_file is platform independent, writes the content verbatim, and fails
# loudly if it cannot.
resource "local_file" "jumpbox_ssh_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/../ssh_keys/ubuntu-jumpbox.pem"
  file_permission = "0600"
}
