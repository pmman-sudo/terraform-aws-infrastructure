terraform {
  backend "s3" {
    bucket       = "pmman-sudo-terraform-state-2026"
    key          = "terraform-aws-infrastructure/dev/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}