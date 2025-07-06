# Terraform: AWS Infrastructure

This folder contains all infrastructure-as-code (IaC) for the HomeLab environment. Resources are defined in modules for reusability and clarity.

## What’s Provisioned?

* VPC, subnet, internet gateway, and routing
* Security groups for EC2 (SSH, SMTP, HTTPS, IMAPS, etc.)
* EC2 instance for the mailserver (with S3 backup and IAM role)
* S3 bucket (encrypted, versioned) for mailserver data/config
* Route53 DNS records (A, MX, SPF, DKIM, SES verification)
* IAM roles/policies for S3 and EC2
* Optional: SES for email sending/relay

---

## 🚨 Manual Setup Checklist (Required Before First Apply)

**These resources are usually set up once, outside of Terraform, for best practices and to avoid state locking issues.**

### 1. Route53 Domain

* Register your domain with a registrar (Namecheap, etc.).
* In AWS Route53, **create a Hosted Zone** for your domain.
* At your registrar, update the domain's nameservers to those given by Route53.
* Copy your Route53 Hosted Zone ID (`Zxxxxxxxxxxxxxx`) for use in `terraform.tfvars`.

### 2. Terraform State S3 Bucket

* Create an S3 bucket to store Terraform state, e.g. `homelab-tfstate`.
* Enable **encryption** (AES-256 or SSE-KMS recommended).
* Do **NOT** enable "Block all public access" (this is the default; keep it blocked!).
* You only need to create this bucket *once*.

### 3. DynamoDB Table for Locking

* Create a DynamoDB table (e.g. `homelab-tflocks`) with a primary key:

  * Name: `LockID`
  * Type: `String`
* This table is required for Terraform state locking if using S3 backend.
* You only need to create this table *once*.

### 4. AWS Credentials

* Create an **IAM user** (or use a profile/role) with permissions for:

  * EC2, VPC, S3, Route53, IAM, DynamoDB, SES
* Use these credentials (via `~/.aws/credentials`, `AWS_PROFILE`, or env vars) for Terraform CLI.

---

## Usage

### 1. Configure Variables

* Copy `terraform.tfvars.example` to `terraform.tfvars` and edit values:

  * `region`
  * `profile`
  * `route53_zone_id`
  * `mail_backup_bucket_name`
  * `mail_backup_bucket_prefix`
  * etc.

### 2. Initialize & Deploy

```sh
cd terraform
terraform init
terraform apply
```

* Review the plan before applying.

### 3. State Backend

* State is managed in your S3 bucket with DynamoDB for locking.
* Don’t change these settings unless you change your AWS environment.

### 4. Outputs

* After apply, note the outputs:

  * EC2 public IP
  * S3 bucket name
  * Instance profile name

### 5. Manual Steps (After Apply)

* **SES out of sandbox:**

  * If you want to email non-verified addresses, request production SES access via AWS console.
* **Domain propagation:**

  * Wait for DNS to update after initial setup.
* **IAM roles:**

  * Make sure any extra IAM permissions are attached if needed.

---

## Deployment Order

1. Complete **Manual Setup** above.
2. Run all Terraform to create network, EC2, S3, IAM, and DNS.
3. Use output values for Ansible inventory and config.
4. (If needed) Use scripts to update DNS records or for manual failover.

---

## Notes

* **Destroying infra:**

  * Some resources use `prevent_destroy = true` for safety. Remove that block if you need to delete.
* **Manual resource deletion:**

  * If you delete something manually, either remove it from code or run `terraform state rm` to keep things in sync.
* **State file:**

  * Don’t commit real state files to git. `.terraform` is gitignored.

---

**See the main project README for the big picture, and `ansible/` for configuration and deployment after infra is ready.**
