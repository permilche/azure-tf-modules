# Azure Terraform Modules

> **Disclaimer:** this is a personal project and not an official HashiCorp product. It is not officially supported or maintained by HashiCorp, and I share it to help out the community. It comes "as is", without any warranty. There may be errors, and the Terraform, provider or module versions used here may get deprecated or stop working. Please review and test everything outside production before using it, and use it at your own risk. The repository is public and issues and pull requests are welcome, but I review and validate each one myself, so there is no guaranteed response time, no promise to merge, and no support SLA (see [CONTRIBUTING](.github/CONTRIBUTING.md)). All names, IDs and values are examples or placeholders, so never commit credentials. Terraform, HCP Terraform and Terraform Enterprise are trademarks of HashiCorp.

A collection of reusable Terraform modules for managing Microsoft Azure infrastructure.

## Available Modules

| Module | Description |
|--------|-------------|
| [`communication-service`](./communication-service/README.md) | Azure Communication Service linked to an email domain, with SMTP authentication through a Microsoft Entra ID application |
| ... |

## Repository Structure

Each module lives in its own top-level directory:

```
.
├── README.md
└── communication-service/
    ├── main.tf           # Resource definitions
    ├── variables.tf      # Input variables
    ├── outputs.tf        # Outputs
    ├── providers.tf      # Terraform and provider version constraints
    └── README.md         # Module documentation
```

## Design Principles

- **Single responsibility**: each module covers one resource or a closely related set of resources
- **Composable**: modules take IDs and names as inputs, so they can be combined with other modules (including [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)) or plain resources
- **Entra ID integration**: authentication is based on Microsoft Entra ID (formerly Azure AD) where applicable
- **Secure outputs**: secrets are exposed only through outputs marked `sensitive`
- **Validation**: input validation is used where it catches common mistakes

## Requirements

Requirements are defined per module in its `providers.tf`. The current module needs:

| Name | Version |
|------|---------|
| terraform | >= 1.9 |
| azurerm | ~> 4.60 |
| azuread | ~> 3.9.0 |
| azapi | ~> 2.4 |

You also need valid Azure credentials for the target subscription and tenant. Modules that create Entra ID objects additionally require permissions to manage app registrations.

## Getting Started

1. Reference a module from your configuration:

   ```hcl
   module "communication_service" {
     source = "./communication-service"

     communication_service_name = "my-comm-service"
     resource_group_name        = "my-resource-group"
     email_service_domain_id    = "<full resource ID of the email domain, including /domains/<name>>"
     app_display_name           = "SMTP Authentication App"
     smtp_username              = "noreply"
   }
   ```

2. Initialize, review and apply:

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

Each module's README documents its inputs, outputs, resources and complete examples (for example, wiring the module to the Azure Verified Module for Email Service, storing credentials in Key Vault, and enabling diagnostic settings).

## Usage Guidelines

- **Pin versions**: pin provider versions and, when consuming modules from Git, pin to a tag or commit (`?ref=`)
- **Read the module README first**: it lists required inputs and caveats
- **Pass data between modules through outputs**
- **Keep secrets out of version control**: `*.tfvars` is git-ignored here. Sensitive outputs are still stored in Terraform state, so use a remote backend with restricted access and encryption
- **Least privilege**: grant only the roles an identity needs (for example, a custom role instead of `Communication and Email Service Owner` where appropriate)
- **Tag your resources**: the modules in this repository do not currently expose a `tags` input, so apply tags with Azure Policy or on resources you manage directly

## Contributing

When adding a new module:

1. Create a top-level directory named after the module, using the structure above
2. Declare provider and Terraform version constraints in `providers.tf`
3. Add `description` and `type` to every variable and output, plus validation where appropriate
4. Mark sensitive outputs with `sensitive = true`
5. Write a module `README.md` with usage examples, inputs, outputs and troubleshooting notes
6. Add the module to the [Available Modules](#available-modules) table
7. Run `terraform fmt -check` and `terraform validate` before committing

## Additional Resources

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Terraform Registry](https://registry.terraform.io/)
- [Terraform azurerm provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform azuread provider](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs)
- [Terraform azapi provider](https://registry.terraform.io/providers/Azure/azapi/latest/docs)
- [Azure Communication Services Documentation](https://learn.microsoft.com/en-us/azure/communication-services/)

## Support

This project is offered as is and **no support is provided** (see the disclaimer at the top of this README and [SUPPORT](.github/SUPPORT.md)). For issues or questions, these resources are the best place to start:

- The README of each module in this repository (see the [Available Modules](#available-modules) table)
- [Terraform azurerm provider documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform azuread provider documentation](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs)
- [Terraform azapi provider documentation](https://registry.terraform.io/providers/Azure/azapi/latest/docs)
- [Azure Communication Services documentation](https://learn.microsoft.com/en-us/azure/communication-services/)

## License

Licensed under the [Mozilla Public License 2.0](LICENSE). See also [CONTRIBUTING](.github/CONTRIBUTING.md), [SUPPORT](.github/SUPPORT.md) and [SECURITY](.github/SECURITY.md).
