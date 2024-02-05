################################
# Input Variables & Locals (calculated vars)
################################


variable "sql_username" {
  description = "SQL and VMs administrator username (Check SQL and VM Username Requirements. Not recommended for production, use different usernames and password for your apps, this is lab env.)"
  type        = string
  sensitive   = true
}

variable "sql_password" {
  description = "SQL and VMs administrator password (Check SQL and VM Username Requirements. Not recommended for production, use different usernames and password for your apps, this is lab env.)"
  type        = string
  sensitive   = true
}


variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created, e.g., westus "
  type        = string
}



variable "sql_database_name" {
  type    = string
  default = "demo-sqldb"
}


variable "deployment_url" {
  type    = string
  default = "https://raw.githubusercontent.com/MicrosoftDocs/mslearn-n-tier-architecture/master/Deployment/"
}


variable "IPAddress" {
  type = string
  description = "Enter your home IP address. If you do not know it you can go to https://whatismyipaddress.com/. For example: 1.2.3.4 ."
  validation {
    condition = can(regex("\\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\b", var.IPAddress))
	error_message = "Could not parse IP address. Please ensure the IP is a valid IPv4 IP address."
  }

}

