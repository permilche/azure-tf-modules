variable "communication_service_name" {
  description = "Name of the Azure Communication Service resource"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where the Communication Service will be created"
  type        = string
}

variable "data_location" {
  description = "Data location for the Communication Service (e.g. Europe, United States)"
  type        = string
  default     = "Europe"
}

variable "email_service_domain_id" {
  description = "Resource ID of the AzureManagedDomain, e.g. \"$${module.avm-res-communication-emailservice.resource_id}/domains/AzureManagedDomain\". Need to add the domains (can be AzureManagedDomain or other) since it's not exposed as a module output in avm-res-communication-emailservice"
  type        = string
}

variable "app_display_name" {
  description = "Display name for the Entra ID App Registration used for SMTP"
  type        = string
}

variable "role_definition_name" {
  description = "Role assigned to the SMTP service principal on the Communication Service scope"
  type        = string
  default     = "Communication and Email Service Owner"
}

variable "smtp_username_resource_name" {
  description = "Name of the smtpUsernames azapi_resource. If not provided (defaults to null) it will be composed with the smtp_username and the '-smtp' suffix. Need to be different than the smtp_username to avoid \"The username cannot be the same as the resource name.\" errors"
  type        = string
  default     = null

  validation {
    condition = var.smtp_username_resource_name == null || var.smtp_username_resource_name != var.smtp_username
    error_message = "smtp_username_resource_name must be different from smtp_username to avoid \"The username cannot be the same as the resource name.\" errors."
  }
}

variable "smtp_username" {
  description = "Username to use for SMTP authentication"
  type        = string
}
