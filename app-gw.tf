# Config Reference 

# https://terraformguru.com/terraform-real-world-on-azure-cloud/30-Azure-Application-Gateway-SSL-SelfSigned/
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway
# https://learn.microsoft.com/en-us/azure/application-gateway/quick-create-terraform

# App Gw Subnet - VNET is in main

resource "azurerm_subnet" "app_gw_subnet" {
  name                 = "AppGwSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.tier_3app_vnet.name
  address_prefixes     = ["10.24.254.0/24"]
}

# PIP of AppGw 

# Public IP Address for Frontend VM
resource "azurerm_public_ip" "appgw_pip" {
  name                = "appgw-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku = "Standard"
  availability_zone   = "No-Zone"
  tags                         = { tier = "presentation" }
}



# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "frontendVM-bkd-pool"
  frontend_port_name             = "http"
  frontend_ip_configuration_name = "app-gw-ip-config"
  http_setting_name              = "app-gw-backend-http-settings"
  listener_name                  = "voteapp.mfk-labs.com"
  request_routing_rule_name      = "route-to-backend"
  redirect_configuration_name    = "rdrcfg"


  # HTTPS
  https_frontend_port_name       = "https"
  https_listener_name            = "https-listener"
  https_request_routing_rule_name = "https-route-to-backend"
  https_setting_name            = "app-gw-backend-https-settings"
  ssl_certificate_name            = "mfk-ssl-certificate"
  
}


################################
# App Gw config
################################


resource "azurerm_application_gateway" "app_gw" {
  name                = "app-gw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "app-gw-ip-config"
    subnet_id = azurerm_subnet.app_gw_subnet.id
  }

################################
# Frontend ports and IP
################################


  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

# Frontend Port  - HTTP Port 80

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

# Frontend Port  - HTTP Port 443
  frontend_port {
    name = local.https_frontend_port_name 
    port = 443    
  }  

################################
# Backend pools
################################


  backend_address_pool {
    name = local.backend_address_pool_name
    ip_addresses = [
      "10.24.1.4"
    ]
  }


################################
# SSL Certificates
################################

# SSL Certificate Block
  ssl_certificate {
    name = local.ssl_certificate_name
    password = var.cert_password
    data = filebase64("${path.module}/certificates/mfk-labs-wild-0924-pass.pfx")
  }

################################
# Listeners
################################


# HTTP Listener
  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  # HTTPS Listener
  http_listener {
    name                           = local.https_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.https_frontend_port_name
    host_name = "voteapp.mfk-labs.com"
    require_sni = true
    protocol                       = "Https"
    ssl_certificate_name           = local.ssl_certificate_name
  }

################################
# Backend pools
################################

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }


# End to End SSL - HTTPS Backend Pool

  backend_http_settings {
    name                  = local.https_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 20
    host_name = "voteapp.mfk-labs.com"
  }

################################
# Request Routing Rules
################################

  # HTTP Request Routing Rule
  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 500
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    # backend_address_pool_name  = local.backend_address_pool_name - uncomment for simple HTTP rule
    # backend_http_settings_name = local.http_setting_name - uncomment for simple HTTP rule
    redirect_configuration_name = local.redirect_configuration_name # Comment out for simple HTTP rule
  }


# Redirect Config for HTTP to HTTPS Redirect - Comment  for simple HTTP rule
  redirect_configuration {
    name = local.redirect_configuration_name
    redirect_type = "Permanent"
    target_listener_name = local.https_listener_name
    include_path = true
    include_query_string = true
  }


  # HTTPS Request Routing Rule - Comment out for simple HTTP rule
  request_routing_rule {
    name                       = local.https_request_routing_rule_name
    priority                   = 501
    rule_type                  = "Basic"
    http_listener_name         = local.https_listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    #backend_http_settings_name = local.http_setting_name # HTTP
    backend_http_settings_name = local.https_setting_name # HTTPS 
  }

  
}
