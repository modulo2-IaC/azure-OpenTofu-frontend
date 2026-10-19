locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      Component   = "frontend"
      ManagedBy   = "OpenTofu"
    },
    var.extra_tags
  )

  name_prefix = "${var.project_name}-front-${var.environment}"
  rg_name     = "rg-vm-${local.name_prefix}-${random_string.suffix.result}"
  vm_name     = "vm-${local.name_prefix}-${random_string.suffix.result}"
  dns_label   = "vm-${local.name_prefix}-${random_string.suffix.result}"
}

# 1. Sufijo aleatorio para unicidad de nombres y DNS en Azure
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

# 2. Grupo de Recursos para el frontend
resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
  tags     = local.common_tags
}

# ---------------------------------------------------------------------------
# RED: VNet + Subnet + IP publica + NSG + NIC
# ---------------------------------------------------------------------------

# 3. Red Virtual (VNet) - espacio de red privado para el frontend (10.1.0.0/16)
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.name_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]
  tags                = local.common_tags
}

# 4. Subred dentro de la VNet
resource "azurerm_subnet" "subnet" {
  name                 = "subnet-frontend"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

# 5. IP publica estatica (para acceder a la aplicacion web desde internet)
# Standard SKU: cuota disponible en Azure Free Trial
resource "azurerm_public_ip" "pip" {
  name                = "pip-${local.name_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = local.dns_label
  tags                = local.common_tags
}

# 6. Network Security Group (firewall)
#    Abre puerto 22 (SSH para administracion), 80 (HTTP) y 443 (HTTPS)
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${local.name_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  # Permite SSH para administracion remota
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Permite HTTP (puerto 80) para el servidor Nginx sirviendo la SPA
  security_rule {
    name                       = "Allow-Frontend-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Permite HTTPS (puerto 443) para conexiones seguras
  security_rule {
    name                       = "Allow-Frontend-HTTPS"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 7. Tarjeta de red virtual (NIC)
resource "azurerm_network_interface" "nic" {
  name                = "nic-${local.name_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# 8. Asociar el NSG a la NIC
resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# ---------------------------------------------------------------------------
# MAQUINA VIRTUAL LINUX (Ubuntu 22.04 LTS)
# ---------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "frontend_vm" {
  name                = local.vm_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  tags                = local.common_tags

  # Autenticacion por contrasena
  admin_password                  = var.admin_password
  disable_password_authentication = false

  # Conectar la VM a la tarjeta de red creada arriba
  network_interface_ids = [azurerm_network_interface.nic.id]

  # Disco del sistema operativo (Standard HDD: optimo para Free Tier)
  os_disk {
    name                 = "osdisk-${local.name_prefix}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  # Imagen de Ubuntu 22.04 LTS de Canonical (sin costo adicional de licenciamiento)
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # ---------------------------------------------------------------------------
  # CLOUD-INIT: configuracion automatica inicial
  # Instala Nginx, Node.js, prepara /var/www/asistencia-front y el script deploy.sh
  # ---------------------------------------------------------------------------
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    admin_username = var.admin_username
    node_version   = var.node_version
    vite_api_url   = var.vite_api_url
    repo_url       = var.repo_url
  }))
}
