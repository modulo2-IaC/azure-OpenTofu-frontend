output "resource_group_name" {
  description = "Nombre del Grupo de Recursos creado"
  value       = azurerm_resource_group.rg.name
}

output "vm_name" {
  description = "Nombre de la Maquina Virtual creada"
  value       = azurerm_linux_virtual_machine.frontend_vm.name
}

output "public_ip_address" {
  description = "Direccion IP publica de la VM (estatica)"
  value       = azurerm_public_ip.pip.ip_address
}

output "vm_fqdn" {
  description = "Nombre DNS completo de la VM"
  value       = azurerm_public_ip.pip.fqdn
}

output "frontend_url" {
  description = "URL HTTP del frontend en la VM (dominio FQDN)"
  value       = "http://${azurerm_public_ip.pip.fqdn}"
}

output "frontend_ip_url" {
  description = "URL HTTP directa por IP publica"
  value       = "http://${azurerm_public_ip.pip.ip_address}"
}

output "configured_api_url" {
  description = "URL del backend API configurada en el frontend"
  value       = var.vite_api_url
}

output "ssh_connection_command" {
  description = "Comando para conectarse a la VM via SSH"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
}

output "upload_command" {
  description = "Comando sugerido para subir el codigo del frontend a la VM"
  value       = "scp -r ../../../../../asistencia-front/. ${var.admin_username}@${azurerm_public_ip.pip.ip_address}:/var/www/asistencia-front/"
}

output "deploy_command" {
  description = "Comando para ejecutar la compilacion y despliegue dentro de la VM via SSH"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.pip.ip_address} '~/deploy.sh'"
}
