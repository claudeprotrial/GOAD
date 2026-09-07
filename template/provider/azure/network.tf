resource "azurerm_virtual_network" "virtual_network" {
  name                = "{{lab_name}}-virtual-network"
  address_space       = ["{{ip_range}}.0/24"]
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "{{lab_name}}-vm-subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["{{ip_range}}.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                 = "{{lab_name}}-subnet-nsg"
  location             = azurerm_resource_group.resource_group.location
  resource_group_name  = azurerm_resource_group.resource_group.name

  security_rule {
    name                          = "AllowSSHInboundOnly"
    priority                      = 100
    direction                     = "Inbound"
    access                        = "Allow"
    protocol                      = "Tcp"
    source_port_range             = "*"
    destination_port_range        = "22"
    source_address_prefix         = var.allowed_source_ip
    destination_address_prefix    = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                       = azurerm_subnet.subnet.id
  network_security_group_id       = azurerm_network_security_group.nsg.id
}

# ---------------------------------------------------------------------------
# Outbound internet access for the lab subnet.
#
# The windows VMs deliberately have no public IP. Azure used to give such VMs
# implicit "default outbound access", but that is retired for subnets created
# from 2025-09-30 onwards, so a freshly created lab subnet has no route to the
# internet at all. The provisioning stage downloads its payloads from the
# internet (for SCCM: the MECM package, SQL Server, the Windows ADK and WinPE),
# so without an explicit egress path ansible fails part way through the install.
#
# A NAT gateway gives the subnet SNAT egress while adding no inbound surface,
# which is the right trade for an intentionally vulnerable lab. It also gives
# the lab a single, stable egress IP.
# ---------------------------------------------------------------------------
resource "azurerm_public_ip" "nat_public_ip" {
  name                = "{{lab_name}}-nat-pip"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat_gateway" {
  name                    = "{{lab_name}}-nat-gw"
  location                = azurerm_resource_group.resource_group.location
  resource_group_name     = azurerm_resource_group.resource_group.name
  sku_name                = "Standard"
  # the default of 4 minutes drops long installer downloads
  idle_timeout_in_minutes = 10
}

resource "azurerm_nat_gateway_public_ip_association" "nat_public_ip_association" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.nat_public_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "nat_subnet_association" {
  subnet_id      = azurerm_subnet.subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
}

resource "azurerm_network_interface" "goad-vm-nic" {
  for_each = var.vm_config

  name                = "{{lab_name}}-vm-${each.value.name}-nic"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "{{lab_name}}-vm-${each.value.name}-nic-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.private_ip_address
  }
}

resource "azurerm_network_interface" "goad-linux-vm-nic" {
  for_each = var.linux_vm_config

  name                = "{{lab_name}}-vm-${each.value.name}-nic"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "{{lab_name}}-vm-${each.value.name}-nic-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.private_ip_address
  }
}
