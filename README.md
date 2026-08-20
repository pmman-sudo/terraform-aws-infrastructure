# ☁️ Terraform AWS Infrastructure

[![Terraform](https://img.shields.io/badge/IaC-Terraform-844FBA?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![EC2](https://img.shields.io/badge/Compute-EC2-FF9900?logo=amazonec2&logoColor=white)](https://aws.amazon.com/ec2/)
[![VPC](https://img.shields.io/badge/Networking-VPC-8A2BE2?logo=amazonaws&logoColor=white)](https://aws.amazon.com/vpc/)
[![S3](https://img.shields.io/badge/State-S3-569A31?logo=amazons3&logoColor=white)](https://aws.amazon.com/s3/)
[![GitHub Actions](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)](https://github.com/pmman-sudo/terraform-aws-infrastructure/actions)
[![OIDC](https://img.shields.io/badge/Auth-OIDC%20%2B%20IAM-232F3E?logo=amazonaws&logoColor=white)](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
[![Docker](https://img.shields.io/badge/Bootstrap-Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)

Infrastructure-as-Code project that provisions a complete AWS networking and compute environment using Terraform, with remote state management and GitHub Actions CI authenticated to AWS through OpenID Connect (OIDC).

The project demonstrates practical Terraform, AWS, Git, CI/CD, remote state management, cloud networking, automated EC2 bootstrapping, and keyless GitHub-to-AWS authentication.

---

## Project Overview

This project uses Terraform to provision and manage AWS infrastructure from code.

The environment currently includes:

- Custom AWS VPC
- Public subnet
- Internet Gateway
- Public route table
- Route table association
- Security Group
- Amazon Linux 2023 EC2 instance
- AWS EC2 key pair
- Automated EC2 bootstrap using `user_data`
- Automatic Docker installation
- S3 remote Terraform state
- Terraform state locking
- GitHub Actions CI
- GitHub OIDC authentication to AWS
- Automated Terraform formatting, validation, and planning

The infrastructure is currently deployed in:

eu-north-1

---

## Architecture

```text
                         Developer
                             │
                             │ git push
                             ▼
                         GitHub
                             │
                             ▼
                     GitHub Actions
                             │
                ┌────────────┴────────────┐
                │                         │
                ▼                         ▼
         Terraform CI               GitHub OIDC
                │                         │
                │                         ▼
                │                 AWS IAM Role
                │                         │
                └────────────┬────────────┘
                             │
                             ▼
                         Terraform
                             │
               ┌─────────────┴─────────────┐
               │                           │
               ▼                           ▼
       S3 Remote Backend              AWS Resources
               │                           │
       terraform.tfstate             Custom VPC
       State Locking                      │
       Versioning                         ▼
                                    Public Subnet
                                         │
                                         ▼
                                  Internet Gateway
                                         │
                                         ▼
                                     Route Table
                                         │
                                         ▼
                                  Security Group
                                         │
                                         ▼
                                    EC2 Instance
                                         │
                                         ▼
                                   bootstrap.sh
                                         │
                                         ▼
                                      Docker
```

---

## Technologies Used

| Technology     | Purpose                                            |
| -------------- | -------------------------------------------------- |
| Terraform      | Infrastructure as Code                             |
| AWS            | Cloud infrastructure                               |
| Amazon EC2     | Compute                                            |
| Amazon VPC     | Network isolation                                  |
| Amazon S3      | Remote Terraform state                             |
| AWS IAM        | Access control                                     |
| GitHub         | Source control                                     |
| GitHub Actions | Terraform CI                                       |
| GitHub OIDC    | Keyless AWS authentication                         |
| Docker         | Container runtime installed on EC2                 |
| PowerShell     | Local development and AWS/Terraform CLI operations |
| Bash           | EC2 bootstrap automation                           |

---

## AWS Infrastructure

Terraform provisions the following architecture:

```text
AWS
│
└── VPC
    │
    ├── CIDR: 10.0.0.0/16
    │
    ├── Internet Gateway
    │
    └── Public Subnet
        │
        ├── CIDR: 10.0.1.0/24
        │
        ├── Route Table
        │   └── 0.0.0.0/0 → Internet Gateway
        │
        └── EC2 Instance
            │
            ├── Amazon Linux 2023
            ├── Public IPv4 address
            ├── Security Group
            ├── SSH access
            └── Docker
```

---

## Repository Structure

```text
terraform-aws-infrastructure/
│
├── .github/
│   └── workflows/
│       └── terraform.yml
│
├── scripts/
│   └── bootstrap.sh
│
├── .gitignore
├── .terraform.lock.hcl
├── backend.tf
├── main.tf
├── outputs.tf
├── providers.tf
├── README.md
├── terraform.tfvars.example
└── variables.tf
```

### File Responsibilities

**`main.tf`**

Defines the AWS infrastructure, including:

* VPC
* subnet
* Internet Gateway
* routing
* Security Group
* EC2 instance
* AWS key pair
* Amazon Linux AMI lookup

**`providers.tf`**

Defines Terraform and AWS provider requirements.

**`variables.tf`**

Defines configurable Terraform input variables.

**`outputs.tf`**

Exports useful infrastructure information such as:

* VPC ID
* subnet ID
* Security Group ID
* EC2 instance ID
* public IPv4 address
* public DNS name

**`backend.tf`**

Configures the Amazon S3 remote Terraform backend.

**`scripts/bootstrap.sh`**

Automatically configures the EC2 instance during creation.

**`.github/workflows/terraform.yml`**

Defines the GitHub Actions Terraform CI workflow.

---

## EC2 Bootstrap Automation

The EC2 instance is automatically configured using Terraform `user_data`.

The bootstrap script performs the following operations:

```bash
#!/bin/bash

set -e

dnf update -y

dnf install -y docker

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user
```

This means a newly provisioned EC2 instance automatically receives a working Docker installation without requiring manual server configuration.

The resulting lifecycle is:

```text
terraform apply
      │
      ▼
EC2 created
      │
      ▼
bootstrap.sh executes
      │
      ▼
Docker installed
      │
      ▼
Docker service enabled
      │
      ▼
Docker service started
```

---

## Dynamic AMI Discovery

Instead of hard-coding an Amazon Machine Image ID, Terraform dynamically retrieves a suitable Amazon Linux 2023 AMI.

This improves portability because AMI IDs can vary between AWS regions and change as new images are released.

Example:

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
```

---

## Terraform Variables

Infrastructure values are configurable rather than being tightly coupled to the Terraform resources.

Example configuration:

```hcl
aws_region         = "eu-north-1"
project_name       = "terraform-devops"
environment        = "dev"

vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"

instance_type = "t3.micro"

ssh_public_key_path = "C:/Users/YOUR_USERNAME/.ssh/terraform-devops.pub"
```

The actual:

```text
terraform.tfvars
```

file is intentionally excluded from Git.

A safe example is provided as:

```text
terraform.tfvars.example
```

---

## Remote Terraform State

Terraform state is stored remotely in Amazon S3 instead of being committed to the repository.

Backend configuration:

```hcl
terraform {
  backend "s3" {
    bucket       = "pmman-sudo-terraform-state-2026"
    key          = "terraform-aws-infrastructure/dev/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

The state architecture is:

```text
Terraform
    │
    ▼
Amazon S3
    │
    └── terraform-aws-infrastructure/
        └── dev/
            └── terraform.tfstate
```

The remote-state setup includes:

* S3 backend
* bucket versioning
* encryption
* public-access blocking
* Terraform state locking

State files are intentionally excluded from Git:

```gitignore
*.tfstate
*.tfstate.*
```

This prevents Terraform state from being accidentally committed to the repository.

---

## GitHub Actions CI

Every push or pull request targeting `main` triggers the Terraform CI workflow.

```text
Developer
    │
    │ git push
    ▼
GitHub
    │
    ▼
GitHub Actions
    │
    ├── Checkout repository
    │
    ├── Setup Terraform
    │
    ├── terraform fmt -check
    │
    ├── Authenticate to AWS
    │
    ├── terraform init
    │
    ├── terraform validate
    │
    └── terraform plan
```

This gives infrastructure changes an automated validation pipeline before an apply operation is performed.

---

## GitHub OIDC Authentication

GitHub Actions authenticates to AWS through OpenID Connect rather than storing permanent AWS access keys in the repository.

```text
GitHub Actions
       │
       │ OIDC token
       ▼
AWS Identity Provider
       │
       ▼
AWS IAM Trust Policy
       │
       ▼
GitHubActionsTerraformRole
       │
       ▼
Temporary AWS Credentials
       │
       ▼
Terraform
```

The GitHub Actions workflow requires:

```yaml
permissions:
  contents: read
  id-token: write
```

AWS then validates the OIDC identity before allowing the GitHub workflow to assume the Terraform IAM role.

This avoids storing long-lived AWS access keys in GitHub Actions.

---

## Terraform CI Commands

### Formatting

```bash
terraform fmt -check -recursive
```

Ensures Terraform files follow standard formatting conventions.

### Initialization

```bash
terraform init
```

Initializes:

* Terraform providers
* S3 backend
* state locking

### Validation

```bash
terraform validate
```

Checks whether the Terraform configuration is structurally valid.

### Planning

```bash
terraform plan -input=false
```

Shows the infrastructure changes Terraform would make without applying them.

---

## Local Usage

### 1. Clone the repository

```bash
git clone https://github.com/pmman-sudo/terraform-aws-infrastructure.git
cd terraform-aws-infrastructure
```

### 2. Create your Terraform variables file

Copy:

```text
terraform.tfvars.example
```

to:

```text
terraform.tfvars
```

and customize the values.

### 3. Configure AWS authentication

Ensure the AWS CLI is authenticated:

```bash
aws sts get-caller-identity
```

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Format the configuration

```bash
terraform fmt
```

### 6. Validate

```bash
terraform validate
```

### 7. Preview changes

```bash
terraform plan
```

### 8. Provision infrastructure

```bash
terraform apply
```

Review the plan carefully before approving infrastructure changes.

---

## Terraform Outputs

After a successful deployment:

```bash
terraform output
```

provides useful values including:

```text
vpc_id
public_subnet_id
security_group_id
ec2_instance_id
ec2_public_ip
ec2_public_dns
```

For example:

```bash
terraform output -raw ec2_public_ip
```

can be used to retrieve the EC2 public IPv4 address.

---

## Infrastructure Verification

Terraform can verify whether the deployed AWS infrastructure matches the configuration:

```bash
terraform plan
```

A synchronized environment produces:

```text
No changes. Your infrastructure matches the configuration.
```

Terraform-managed resources can also be inspected with:

```bash
terraform state list
```

and:

```bash
terraform state show aws_instance.web
```

---

## Security Practices Demonstrated

This project currently demonstrates several infrastructure security practices:

* Terraform state excluded from Git
* Terraform variable files excluded from Git
* SSH private keys excluded from Git
* S3 public access blocked
* S3 state encryption
* S3 state versioning
* Terraform state locking
* GitHub-to-AWS authentication using OIDC
* Temporary AWS credentials for CI
* EC2 Instance Metadata Service configured to require IMDSv2
* Infrastructure changes reviewed through `terraform plan`

---

## Current Project Status

The following functionality has been completed:

```text
Terraform setup                        ✅
AWS provider configuration             ✅
VPC                                    ✅
Public subnet                          ✅
Internet Gateway                       ✅
Route table                            ✅
Route table association                ✅
Security Group                         ✅
Dynamic Amazon Linux AMI               ✅
EC2 instance                           ✅
AWS key pair                           ✅
EC2 bootstrap automation               ✅
Docker installation                    ✅
Terraform variables                    ✅
Terraform outputs                      ✅
Git repository                         ✅
GitHub repository                      ✅
S3 remote state                        ✅
State migration                        ✅
State versioning                       ✅
State locking                          ✅
GitHub Actions CI                      ✅
GitHub OIDC authentication             ✅
Terraform formatting CI                ✅
Terraform validation CI                ✅
Terraform planning CI                  ✅
```

---

## Future Improvements

Several improvements are intentionally reserved for the next iteration of the project.

### SSH Key CI Portability

The current CI workflow creates a temporary SSH key so Terraform can evaluate the key-pair resource.

A future iteration will improve SSH-key handling so CI planning is completely independent of developer-specific local key paths.

### Security Hardening

The lab currently allows SSH access more broadly than would be recommended for production.

Future improvements include:

* restrict SSH to trusted CIDR ranges
* least-privilege IAM policies
* replace temporary lab-level `AdministratorAccess`
* further network segmentation
* private application workloads
* HTTPS through a load balancer
* AWS Systems Manager Session Manager as an alternative to direct SSH

### Destroy/Recreate Reproducibility Test

A future test will verify complete Infrastructure-as-Code reproducibility:

```text
terraform destroy
        ↓
Infrastructure removed
        ↓
terraform apply
        ↓
Infrastructure recreated
        ↓
Bootstrap executed
        ↓
Docker verified
        ↓
terraform plan
        ↓
No changes
```

---

## Key DevOps Concepts Demonstrated

This project demonstrates practical experience with:

* Infrastructure as Code
* declarative infrastructure
* Terraform state management
* remote Terraform backends
* Terraform state locking
* AWS networking
* cloud compute
* automated server bootstrapping
* Git version control
* CI pipelines
* GitHub Actions
* AWS IAM
* workload identity federation
* OIDC
* temporary cloud credentials
* infrastructure validation
* infrastructure planning
* environment configuration
* Docker provisioning

---

## Lessons Learned

Building this project provided hands-on experience with the full Terraform lifecycle:

```text
Write
  ↓
Format
  ↓
Initialize
  ↓
Validate
  ↓
Plan
  ↓
Apply
  ↓
Inspect state
  ↓
Modify
  ↓
Plan again
```

It also demonstrated the relationship between Terraform's three primary views of infrastructure:

```text
Terraform Configuration
        │
        ▼
    Desired State

Terraform State
        │
        ▼
Terraform's Resource Mapping

AWS Infrastructure
        │
        ▼
     Real State
```

Terraform compares these views to determine what infrastructure changes are required.

The project also introduced a production-style CI authentication model:

```text
GitHub Actions
      ↓
OIDC
      ↓
AWS IAM
      ↓
Temporary Credentials
```

rather than relying on permanent cloud credentials stored as CI secrets.

---

## Author

**Paul Iyen**

DevOps / Cloud / Cybersecurity

GitHub: [pmman-sudo](https://github.com/pmman-sudo)

---

## Project Roadmap

This project is part of a broader hands-on DevOps engineering portfolio focused on:

* Terraform
* AWS
* Docker
* Kubernetes
* CI/CD
* observability
* DevSecOps
* GitOps
* cloud infrastructure automation

---

## Disclaimer

This repository is a learning and portfolio project.

Some configurations are intentionally simplified for lab use and should be further hardened before being used for production workloads.