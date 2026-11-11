output "smtp_username" {
  description = "Username used for SMTP authentication against the Communication Service"
  value       = var.smtp_username
}

output "smtp_password" {
  description = "SMTP password (Entra App Registration client secret) used to authenticate against the Communication Service"
  value       = azuread_application_password.this.value
  sensitive   = true
}

output "communication_service_id" {
  description = "Resource ID of the Azure Communication Service"
  value       = azurerm_communication_service.this.id
}