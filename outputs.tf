################################
# Output values
################################


output "Website_IP_URL" {
  value = "http://${azurerm_public_ip.frontend-pip}"
}


output "database_name" {
  description = "Database name of the Azure SQL Database created."
  value       = azurerm_mssql_database.sql_db
  
}

output "sql_server_fqdn" {
  description = "Fully Qualified Domain Name (FQDN) of the Azure SQL Database created."
  value       = azurerm_mssql_server.sql_server.fully_qualified_domain_name
}