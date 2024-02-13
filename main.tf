################################
# Resource Group
################################


resource "azurerm_resource_group" "rg" {
  location = var.location
  name     = var.resource_group_name
}


resource "random_pet" "sql-var" {
  prefix = "sql"
  length    = 2
  separator = "-"
}

################################
# Low Analytics Workspace
################################

# A log analytics workspace to save your logs 

resource "azurerm_log_analytics_workspace" "log_analytics_ws" {
  name                = "LAW-3tier-${var.location}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}



################################
# Virtual Networks & Subnets
################################

# Create virtual network

# Main VNET

resource "azurerm_virtual_network" "tier_3app_vnet" {
  name                = "Tier3AppVnet"
  address_space       = ["10.24.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnets

resource "azurerm_subnet" "frontend_subnet" {
  name                 = "frontend-snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.tier_3app_vnet.name
  address_prefixes     = ["10.24.1.0/24"]
}


resource "azurerm_subnet" "backend_subnet" {
  name                 = "backend-snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.tier_3app_vnet.name
  address_prefixes     = ["10.24.2.0/24"]
  service_endpoints = ["Microsoft.Sql"]
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "db-snet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.tier_3app_vnet.name
  address_prefixes     = ["10.24.3.0/24"]
}



################################
# Network security groups (NSGs)
################################


# Create Network Security Group and rule
resource "azurerm_network_security_group" "frontend_nsg" {
  name                = "FrontendNSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                         = { tier = "presentation" }

  security_rule {
    name                       = "Allow_all_home"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.IPAddress
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "http"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https"
    priority                   = 310
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "appgw_inbound"
    priority                   = 320
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  

}


resource "azurerm_network_security_group" "backend_nsg" {
  name                = "BackendNSG"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                         = { tier = "application" }

}


################################
# Subnet Associations with NSG
################################


# Connect the security group to the subnets

# Frontend subnet Association

resource "azurerm_subnet_network_security_group_association" "frontend_association" {
  subnet_id      = azurerm_subnet.frontend_subnet.id
  network_security_group_id = azurerm_network_security_group.frontend_nsg.id

}

resource "azurerm_subnet_network_security_group_association" "backend_association" {
  subnet_id      = azurerm_subnet.backend_subnet.id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id

}

resource "azurerm_subnet_network_security_group_association" "appgw_association" {
  subnet_id      = azurerm_subnet.app_gw_subnet.id
  network_security_group_id = azurerm_network_security_group.frontend_nsg.id

}

################################
# Public IP
################################

# Public IP Address for Frontend VM
resource "azurerm_public_ip" "frontend-pip" {
  name                = "frontend-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku = "Standard"
  availability_zone   = "No-Zone"
  tags                         = { tier = "presentation" }
}


################################
# Network Interface Cards (NICs)
################################


resource "azurerm_network_interface" "frontend_nic" {
  name                = "FrontendNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                         = { tier = "presentation" }

  ip_configuration {
    name                          = "Frontend_nic_configuration"
    subnet_id                     = azurerm_subnet.frontend_subnet.id
    private_ip_address_allocation = "static"
    #private_ip_address_allocation = "Dynamic"
    private_ip_address            = "${cidrhost("10.24.1.0/24", 4)}"
    public_ip_address_id          = azurerm_public_ip.frontend-pip.id
    
  }
}

resource "azurerm_network_interface" "backend_nic" {
  name                = "BackendNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                         = { tier = "application" }
  

  ip_configuration {
    name                          = "Backend_nic_configuration"
    subnet_id                     = azurerm_subnet.backend_subnet.id
    private_ip_address_allocation = "static"
    #private_ip_address_allocation = "Dynamic"
    private_ip_address            = "${cidrhost("10.24.2.0/24", 4)}"
    #public_ip_address_id          = azurerm_public_ip.frontend-pip.id
    
  }
}


################################
# Virtual Machines (VMs)
################################


# Create virtual machine

# Frontend VM

resource "azurerm_linux_virtual_machine" "frontend_vm" {
  name                  = "FrontendVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.frontend_nic.id]
  size                  = "Standard_B1s"
  tags                         = { tier = "presentation" }

  os_disk {
    name                 = "FrontendOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

    computer_name                   = "FrontendVM"
    admin_username                  = var.sql_username
    admin_password                  = var.sql_password
    disable_password_authentication = false

}


resource "azurerm_virtual_machine_extension" "frontend_apache_ext" {
  name                 = "apache-ext"
  virtual_machine_id   = azurerm_linux_virtual_machine.frontend_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  auto_upgrade_minor_version = true



  settings = <<SETTINGS
    {
      "skipDos2Unix": true
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "commandToExecute": "sh setup-votingweb.sh",
      "fileUris": [
        "${var.deployment_url_web}setup-votingweb.sh",
        "${var.deployment_url_web}votingweb.conf",
        "${var.deployment_url_web}votingweb.service",
        "${var.deployment_url_web}votingweb.zip"
      ]
    }
PROTECTED_SETTINGS


#   settings = <<SETTINGS
#     {
#       "skipDos2Unix": true
#     }
# SETTINGS

#   protected_settings = <<PROTECTED_SETTINGS
#     {
#       "commandToExecute": "sh setup-votingweb.sh",
#       "fileUris": [
#         "${path.module}/setup-files/setup-votingweb.sh",
#         "${path.module}/setup-files/votingweb.conf",
#         "${path.module}/setup-files/votingweb.service",
#         "${path.module}/setup-files/votingweb.zip"
#       ]
#     }
# PROTECTED_SETTINGS


  # settings = {
  #     skipDos2Unix = true
  #   }

  # protected_settings = {
  #     "commandToExecute": "sh setup-votingweb.sh",
  #     fileUris = [
  #       "${path.module}/setup-files/setup-votingweb.sh",
  #       "${path.module}/setup-files/votingweb.conf",
  #       "${path.module}/setup-files/votingweb.service",
  #       "${path.module}/setup-files/votingweb.zip"
  #     ]
  #   }

    depends_on = [
    azurerm_linux_virtual_machine.frontend_vm
  ]
}


# Backend VM

resource "azurerm_linux_virtual_machine" "backend_vm" {
  name                  = "BackendVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.backend_nic.id]
  size                  = "Standard_B1s"
  tags                         = { tier = "application" }

  os_disk {
    name                 = "BackendOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "BackendVM"
  admin_username                  = var.sql_username
  admin_password                  = var.sql_password
  disable_password_authentication = false
}

resource "azurerm_virtual_machine_extension" "backend_apache_ext" {
  name                 = "backend-apache-ext"
  virtual_machine_id   = azurerm_linux_virtual_machine.backend_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "skipDos2Unix": true,
      "fileUris": [
        "${var.deployment_url_data}setup-votingdata.sh",
        "${var.deployment_url_data}votingdata.conf",
        "${var.deployment_url_data}votingdata.service",
        "${var.deployment_url_data}votingdata.zip"
      ]
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "commandToExecute": "sh setup-votingdata.sh ${random_pet.sql-var.id} ${var.sql_username} ${var.sql_password}"
      
    }
PROTECTED_SETTINGS

# Tried the config below - but gave errors

# settings = <<SETTINGS
#     {
#       "skipDos2Unix": true,
#       "fileUris": [
#         "${path.module}/setup-files/setup-votingweb.sh",
#         "${path.module}/setup-files/votingweb.conf",
#         "${path.module}/setup-files/votingweb.service",
#         "${path.module}/setup-files/votingweb.zip"
#       ]
#     }
# SETTINGS

#   protected_settings = <<PROTECTED_SETTINGS
#     {
#       "commandToExecute": "sh setup-votingdata.sh ${random_pet.sql-var.id} ${var.sql_username} ${var.sql_password}"
      
#     }
# PROTECTED_SETTINGS


  # settings = {
  #   skipDos2Unix = true
  #   fileUris = [
  #     "${path.module}/setup-files/setup-votingweb.sh",
  #     "${path.module}/setup-files/votingweb.conf",
  #     "${path.module}/setup-files/votingweb.service",
  #     "${path.module}/setup-files/votingweb.zip"
  #   ]
  # }

  # protected_settings = {
  #   "commandToExecute": "sh setup-votingdata.sh ${azurerm_mssql_server.sql_server.name} ${var.sql_username} ${var.sql_password}",
    
  # }

  depends_on = [
    azurerm_linux_virtual_machine.backend_vm
  ]
}

# For next steps, replace VMs with App service and web apps

################################
# App Service
################################

# Create an App Service Plan
# resource "azurerm_app_service_plan" "plan" {
#   name                = "app_service_plan"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   kind = "Linux"

#   sku {
#     tier = "Basic"
#     size = "B1"
#   }
# }

################################
# Web apps
################################

# # Create a Web App for the front-end
# resource "azurerm_app_service" "front_end" {
#   name                = "front-end-app"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   app_service_plan_id = azurerm_app_service_plan.plan.id
# }

# # Create a Web App for the back-end
# resource "azurerm_app_service" "back_end" {
#   name                = "back-end-app"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   app_service_plan_id = azurerm_app_service_plan.plan.id
# }


################################
# Azure SQL 
################################


# Create an Azure SQL Database
resource "azurerm_mssql_server" "sql_server" {
  name                         = random_pet.sql-var.id
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_username
  administrator_login_password = var.sql_password
  minimum_tls_version          = "1.2"
  tags                         = { tier = "data" }
}

resource "azurerm_mssql_database" "sql_db" {
  name                = "demo-sqldb"
  server_id = azurerm_mssql_server.sql_server.id
  sku_name  = "S0"
  collation = "SQL_Latin1_General_CP1_CI_AS"
  tags                         = { tier = "data" }
}


resource "azurerm_mssql_virtual_network_rule" "sql-vnet-rule" {
  name      = "sql-vnet-rule"
  server_id = azurerm_mssql_server.sql_server.id
  subnet_id = azurerm_subnet.backend_subnet.id

  depends_on = [
    azurerm_mssql_server.sql_server
  ]
}


