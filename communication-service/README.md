# Azure Communication Service Module

Terraform module that creates an Azure Communication Service linked to an email domain, with SMTP authentication backed by a Microsoft Entra ID application registration.

## Overview

This module provisions:

- **Azure Communication Service** (`azurerm_communication_service`)
- **Email Domain Association** (`azurerm_communication_service_email_domain_association`): links the Communication Service to an existing Email Communication Service domain
- **Entra ID App Registration** (`azuread_application_registration`) and **Service Principal** (`azuread_service_principal`)
- **Role Assignment** (`azurerm_role_assignment`): grants the service principal a role on the Communication Service
- **Application Password** (`azuread_application_password`): the client secret used as the SMTP password
- **SMTP Username** (`azapi_resource`, `Microsoft.Communication/communicationServices/smtpUsernames@2024-09-01-preview`): links the SMTP username to the Entra application (there is no `azurerm` resource for this yet)

The module does **not** create the resource group or the Email Communication Service / domain. Both must already exist (or be created elsewhere in your configuration).

## Usage

### Basic example

```hcl
module "communication_service" {
  source = "./communication-service"

  communication_service_name = "my-comm-service"
  resource_group_name        = "my-resource-group"
  data_location              = "Europe"
  email_service_domain_id    = "/subscriptions/<sub-id>/resourceGroups/my-resource-group/providers/Microsoft.Communication/emailServices/my-email-service/domains/AzureManagedDomain"
  app_display_name           = "SMTP Authentication App"
  smtp_username              = "noreply"
}
```

### Complete example with the Azure Verified Module for Email Service

```hcl
resource "azurerm_resource_group" "main" {
  name     = "my-resource-group"
  location = "westeurope"
}

module "email_service" {
  source  = "Azure/avm-res-communication-emailservice/azurerm"
  version = "0.3.0"

  name          = "my-email-service"
  parent_id     = azurerm_resource_group.main.id # resource group ID, not name
  location      = "global"
  data_location = "Europe"

  email_communication_service_domains = {
    azure_managed = {
      name              = "AzureManagedDomain"
      domain_management = "AzureManaged"
    }
  }
}

module "communication_service" {
  source = "./communication-service"

  communication_service_name = "my-comm-service"
  resource_group_name        = azurerm_resource_group.main.name
  data_location              = "Europe"
  email_service_domain_id    = module.email_service.domain_resource_ids["azure_managed"]

  app_display_name            = "My App SMTP Auth"
  smtp_username               = "noreply"
  smtp_username_resource_name = "noreply-smtp-resource"
  role_definition_name        = "Communication and Email Service Owner"
}

output "smtp_config" {
  value = {
    server   = "smtp.azurecomm.net"
    port     = 587
    username = module.communication_service.smtp_username
    password = module.communication_service.smtp_password
  }
  sensitive = true
}
```

> Versions `0.1.x` and `0.2.x` of the AVM module take `resource_group_name` instead of `parent_id` and do not expose domain IDs. With those versions, build the domain ID manually: `"${module.email_service.resource_id}/domains/AzureManagedDomain"`.

### Custom role

Microsoft documents a least-privilege alternative to the built-in role: a custom role with `Microsoft.Communication/CommunicationServices/Read`, `Microsoft.Communication/CommunicationServices/Write` and `Microsoft.Communication/EmailServices/write`. Create it yourself and pass its name:

```hcl
module "communication_service" {
  source = "./communication-service"

  communication_service_name = "my-comm-service"
  resource_group_name        = "my-resource-group"
  email_service_domain_id    = var.email_domain_id
  app_display_name           = "Custom SMTP App"
  smtp_username              = "custom-smtp"

  role_definition_name = "My Custom SMTP Role"
}
```

### Storing credentials in Key Vault

```hcl
resource "azurerm_key_vault_secret" "smtp_username" {
  name         = "smtp-username"
  value        = module.communication_service.smtp_username
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "smtp_password" {
  name         = "smtp-password"
  value        = module.communication_service.smtp_password
  key_vault_id = azurerm_key_vault.main.id
}
```

### Diagnostic settings with Azure Monitor

```hcl
resource "azurerm_monitor_diagnostic_setting" "comm_service" {
  name                       = "diag-comm-service"
  target_resource_id         = module.communication_service.communication_service_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "EmailSendMailOperational"
  }
}
```

Other email log categories include `EmailStatusUpdateOperational` and `EmailUserEngagementOperational`.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9 |
| azurerm | ~> 4.60 |
| azuread | ~> 3.9.0 |
| azapi | ~> 2.4 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 4.60 |
| azuread | ~> 3.9.0 |
| azapi | ~> 2.4 |

## Resources

| Name | Type |
|------|------|
| azurerm_communication_service.this | resource |
| azurerm_communication_service_email_domain_association.this | resource |
| azuread_application_registration.this | resource |
| azuread_service_principal.this | resource |
| azurerm_role_assignment.this | resource |
| azuread_application_password.this | resource |
| azapi_resource.smtp_username | resource |
| azurerm_client_config.current | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| communication_service_name | Name of the Azure Communication Service resource | `string` | n/a | yes |
| resource_group_name | Name of the existing resource group where the Communication Service will be created | `string` | n/a | yes |
| data_location | Data location for the Communication Service (e.g. Europe, United States). Changing it forces a new Communication Service | `string` | `"Europe"` | no |
| email_service_domain_id | Full resource ID of the email domain to link, including `/domains/<name>` (e.g. `AzureManagedDomain`) | `string` | n/a | yes |
| app_display_name | Display name for the Entra ID App Registration used for SMTP | `string` | n/a | yes |
| role_definition_name | Role assigned to the SMTP service principal on the Communication Service scope | `string` | `"Communication and Email Service Owner"` | no |
| smtp_username_resource_name | Name of the smtpUsernames azapi_resource. If `null`, it is composed as `<smtp_username>-smtp`. Must differ from `smtp_username` (enforced by a validation rule) | `string` | `null` | no |
| smtp_username | Username to use for SMTP authentication | `string` | n/a | yes |

The module has no `tags` input.

## Outputs

| Name | Description |
|------|-------------|
| smtp_username | Username used for SMTP authentication against the Communication Service |
| smtp_password | SMTP password (Entra App Registration client secret) used to authenticate against the Communication Service (sensitive) |
| communication_service_id | Resource ID of the Azure Communication Service |

## SMTP Configuration

After deploying, configure your SMTP client with the module outputs:

| Setting | Value |
|---------|-------|
| Server | `smtp.azurecomm.net` |
| Port | `587` (recommended) or `25` |
| TLS | STARTTLS, TLS 1.2 or later |
| Username | `smtp_username` output |
| Password | `smtp_password` output (sensitive) |

Use the DNS name, not an IP address. Make sure the port is not blocked by your network or ISP.

### Python (smtplib)

```python
import smtplib
from email.mime.text import MIMEText

smtp_server = "smtp.azurecomm.net"
smtp_port = 587
smtp_username = "<output from module>"
smtp_password = "<output from module>"

msg = MIMEText("Hello from Azure Communication Services!")
msg["Subject"] = "Test Email"
msg["From"] = "noreply@yourdomain.com"  # must belong to the linked email domain
msg["To"] = "recipient@example.com"

with smtplib.SMTP(smtp_server, smtp_port) as server:
    server.starttls()
    server.login(smtp_username, smtp_password)
    server.send_message(msg)
```

### Node.js (nodemailer)

```javascript
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: 'smtp.azurecomm.net',
  port: 587,
  secure: false, // STARTTLS is negotiated on port 587
  auth: {
    user: process.env.SMTP_USERNAME,
    pass: process.env.SMTP_PASSWORD
  }
});

await transporter.sendMail({
  from: 'noreply@yourdomain.com',
  to: 'recipient@example.com',
  subject: 'Test Email',
  text: 'Hello from Azure!'
});
```

## Important Notes

### SMTP username resource name

`smtp_username_resource_name` must differ from `smtp_username`, otherwise Azure rejects it with `The username cannot be the same as the resource name.` The module enforces this with a validation rule. If you leave it `null`, `-smtp` is appended to `smtp_username`.

### SMTP username format

Per Microsoft, an SMTP username can be free-form or an email address. If it is an email address, its domain must be one of the Communication Service's linked domains.

### Email domain association

`email_service_domain_id` must be the full resource ID of the domain (`.../emailServices/<name>/domains/<domain>`), not just the email service ID. `AzureManagedDomain` is the name of the Azure-managed domain. Custom domains use their own name. With `Azure/avm-res-communication-emailservice/azurerm` `>= 0.3.0` use the `domain_resource_ids` output. Earlier versions only expose `resource_id`, so append `/domains/<name>` yourself.

### Role assignments

The default `Communication and Email Service Owner` role grants access to all Communication and Email operations. Use `role_definition_name` to supply a narrower custom role if your organization requires it.

### Data location

`data_location` is where the Communication Service stores data at rest, and changing it forces a new resource. Supported values (per the `azurerm` provider) are `Africa`, `Asia Pacific`, `Australia`, `Brazil`, `Canada`, `Europe`, `France`, `Germany`, `India`, `Japan`, `Korea`, `Norway`, `Switzerland`, `UAE`, `UK`, `usgov` and `United States`. Choose based on your data residency requirements.

### Secret handling

`smtp_password` is a sensitive output, but it is still stored in Terraform state. Use a remote backend with restricted access and encryption. To rotate the secret, replace the password resource:

```bash
terraform apply -replace='module.communication_service.azuread_application_password.this'
```

## Troubleshooting

### Authentication failures

1. Verify `smtp_username` and `smtp_password` match the module outputs
2. Check that the service principal has the expected role assignment on the Communication Service
3. Ensure the email domain is linked to the Communication Service and the sender address belongs to it
4. Verify server and port (`smtp.azurecomm.net:587`) and that TLS 1.2+ is supported by your client

### Resource name conflicts

On `The username cannot be the same as the resource name.`, set `smtp_username_resource_name` to a value different from `smtp_username`, or omit it to use the default `-smtp` suffix.

### Permission issues

1. Verify the service principal was created successfully
2. Check the role assignment scope
3. Wait a few minutes for Entra ID propagation
4. Verify `role_definition_name` exists in your subscription

### Email domain association errors

- Ensure `email_service_domain_id` includes `/domains/<name>`
- Verify the email service and domain exist and are accessible
- For custom domains, check that the domain is verified

## References

- [Azure Communication Services Documentation](https://learn.microsoft.com/en-us/azure/communication-services/)
- [SMTP Authentication with Entra ID](https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/send-email-smtp/smtp-authentication)
- [Communication Services SMTP Usernames API](https://learn.microsoft.com/en-us/azure/templates/microsoft.communication/communicationservices/smtpusernames)
- [AVM Email Communication Service module](https://registry.terraform.io/modules/Azure/avm-res-communication-emailservice/azurerm/latest)

## License

See the root repository LICENSE file for license information. (No LICENSE file is currently present in the repository.)
