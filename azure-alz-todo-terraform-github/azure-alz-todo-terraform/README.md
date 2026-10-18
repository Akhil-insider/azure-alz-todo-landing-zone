# Azure Landing Zone Hub-Spoke ToDo Lab

A portfolio-ready Terraform reference implementation inspired by a hands-on Azure Portal lab:
- Management groups and subscription placement (optional / separately applied)
- Hub-and-spoke VNets with `for_each`
- NSGs and subnet associations
- NAT Gateways for outbound connectivity
- Azure Firewall Premium + network rule collection
- UDRs for selected east-west flows
- Azure SQL logical server/database + Private Endpoint + Private DNS
- Linux frontend/backend VMs
- Application Gateway v2 HTTP ingress and GoDaddy DNS record (optional)
- Reusable modules, `for_each`, and `dynamic` blocks

> **Important:** This is a reference scaffold, not a blind “apply everything” script. Azure Firewall Premium, Application Gateway v2, NAT Gateways, VMs and Azure SQL can incur charges. The original lab subscription showed Free Trial expired/services paused. Review cost and subscription state before applying. The original lab's exact live state may have changed.

## Repository structure

```text
.
├── README.md
├── docs/
│   ├── HLD.md
│   ├── LLD.md
│   ├── INTERVIEW_NOTES.md
│   └── architecture.mmd
├── environments/lab/
│   ├── backend.tf.example
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── versions.tf
└── modules/
    ├── network/
    ├── nsg/
    ├── nat/
    ├── firewall/
    ├── routes/
    ├── private-dns/
    ├── sql-private/
    ├── linux-vm/
    ├── app-gateway/
    └── godaddy-dns/
```

## Design notes / intentional deviations

1. Terraform uses a map of VNets/subnets and `for_each` rather than copy-pasted resources.
2. NSG security rules use `dynamic "security_rule"`; Application Gateway probes/listeners/rules and Firewall rule collections use `dynamic` blocks where provider schemas support them.
3. The VM module is intentionally minimal. App packages and application code should be deployed with cloud-init, Ansible, a pipeline, or a configuration-management tool; secrets must not be embedded in user data.
4. The root config demonstrates core network and SQL private access. Optional expensive modules (Firewall, NAT, Application Gateway, VMs) are kept separate so you can enable and test them in stages.
5. Azure SQL Private Endpoint + Private DNS does not automatically force traffic through Azure Firewall. Effective routes, subnet policy settings, and symmetric routing must be validated.
6. A private VM cannot be SSHed to from a normal laptop without VPN, Bastion, or a jump host. Use Run Command during this lab.
7. For production, prefer Azure Verified Modules or organization-approved modules, remote state with locking, CI validation, policy checks, managed identities, Key Vault, monitoring, and a reviewed landing-zone design.

## Prerequisites

- Terraform >= 1.6
- Azure CLI logged in: `az login`
- A target subscription with quota and permissions
- GoDaddy API credentials only if using the optional DNS module
- Terraform state stored remotely for team use (Azure Storage backend recommended)

## Suggested staged workflow

```bash
cd environments/lab
cp terraform.tfvars.example terraform.tfvars
# Edit subscription ID, region, CIDRs, names, and opt-in flags.
az account set --subscription "<SUBSCRIPTION_ID>"
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out tfplan
# Review the plan and cost implications carefully before apply.
terraform apply tfplan
```

Destroy only after reviewing dependencies and data retention:
```bash
terraform plan -destroy
# terraform destroy
```

## Safe GitHub publishing

- Never commit `terraform.tfvars`, `.tfstate`, `.tfstate.backup`, plan files, private keys, certificates, `.env`, or credentials.
- Commit `terraform.tfvars.example`, not the real tfvars.
- Rotate SQL credentials that were entered into portal Run Command during the original lab.
- Add GitHub Actions for `terraform fmt -check`, `terraform validate`, and `tflint` before calling this production-ready.
