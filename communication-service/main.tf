resource "azurerm_communication_service" "this" {
  name                = var.communication_service_name
  resource_group_name = var.resource_group_name
  data_location        = var.data_location
}

resource "azurerm_communication_service_email_domain_association" "this" {
  communication_service_id = azurerm_communication_service.this.id
  email_service_domain_id  = var.email_service_domain_id
}

resource "azuread_application_registration" "this" {
  display_name = var.app_display_name
}

resource "azuread_service_principal" "this" {
  client_id = azuread_application_registration.this.client_id
}

resource "azurerm_role_assignment" "this" {
  scope                = azurerm_communication_service.this.id
  role_definition_name = var.role_definition_name
  principal_id         = azuread_service_principal.this.object_id
}

resource "azuread_application_password" "this" {
  application_id = azuread_application_registration.this.id
}

data "azurerm_client_config" "current" {}

# No official azurerm provider resource yet, instead, use the ARM API directly
# https://learn.microsoft.com/en-us/azure/templates/microsoft.communication/communicationservices/smtpusernames?pivots=deployment-language-terraform
# This resource is used for authentication purposes. It links an Entra application (via entraApplicationId + tenantId) to a chosen username string so the SMTP server knows which identity is logging in via AUTH LOGIN
# https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/send-email-smtp/smtp-authentication?tabs=built-in-role
resource "azapi_resource" "smtp_username" {
  type = "Microsoft.Communication/communicationServices/smtpUsernames@2024-09-01-preview"

  parent_id = azurerm_communication_service.this.id

  name = var.smtp_username_resource_name != null ? var.smtp_username_resource_name : "${var.smtp_username}-smtp"

  body = {
    properties = {
      username           = var.smtp_username
      tenantId           = data.azurerm_client_config.current.tenant_id
      entraApplicationId = azuread_application_registration.this.client_id
    }
  }
}