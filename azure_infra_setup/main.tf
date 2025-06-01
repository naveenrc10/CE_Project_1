data "azurerm_resource_group" "rg" {
  name     = "frontend-rg"
  location = "East US"
}

resource "azurerm_virtual_network" "frontend_vnet" {
  name                = "frontend-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}


resource "azurerm_subnet" "frontend_subnet" {
  name                 = "frontend-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.frontend_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "frontend_lb_public_ip" {
  name                = "frontend-lb-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "frontend_lb" {
  name                = "frontend-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.frontend_lb_public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.frontend_lb.id
  name            = "backend-pool"
  
}


resource "azurerm_lb_probe" "frontend_probe" {
  loadbalancer_id = azurerm_lb.frontend_lb.id
  name            = "http-probe"
  port            = 8080
  protocol        = "Http"
  request_path    = "/api/hello"
  
}

resource "azurerm_network_security_group" "frontend_nsg" {
  name                = "frontend-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-http"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

data "local_file" "startup_script" {
  filename = "${path.module}/Frontend-init.sh"
}


resource "azurerm_subnet_network_security_group_association" "vmss_nsg_assoc" {
  subnet_id                 = azurerm_subnet.frontend_subnet.id
  network_security_group_id = azurerm_network_security_group.frontend_nsg.id
}

resource "azurerm_linux_virtual_machine_scale_set" "frontend_vmss" {
  name                = "frontend-vmss"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard_B1s"
  instances           = 2  # Desired count of VMs
  admin_username      = "ubuntu"
  custom_data         = base64encode(data.local_file.startup_script.content)

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name                      = "frontend-config"
    primary                   = true
    ip_configuration {
      name                          = "frontend-config"
      subnet_id                     = azurerm_subnet.frontend_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_pool.id]
    }
  }

  admin_ssh_key {
    username   = "ubuntu"
    public_key = file(var.ssh_public_key)   # Path to your public key
  } 
 
}

resource "azurerm_lb_rule" "frontend_lb_rule" {
  loadbalancer_id                = azurerm_lb.frontend_lb.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 8080
  backend_port                   = 8080
  frontend_ip_configuration_name = "frontend-ip"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.frontend_probe.id
}
resource "azurerm_lb_nat_rule" "ssh_nat_rule" {
  resource_group_name = azurerm_resource_group.rg.name
  loadbalancer_id                = azurerm_lb.frontend_lb.id
  name                           = "ssh-rule"
  protocol                       = "Tcp"
  frontend_port_start            = 50022
  frontend_port_end              = 50025
  backend_port                   = 22
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
  frontend_ip_configuration_name = "frontend-ip"
}

resource "azurerm_monitor_autoscale_setting" "frontend_autoscale" {
  name                = "frontend-autoscale"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.frontend_vmss.id

  profile {
    name = "autoscale-profile"
    capacity {
      default = 2  # Maintain 2 VM instances
      minimum = 2
      maximum = 2
    }
  
  }
}