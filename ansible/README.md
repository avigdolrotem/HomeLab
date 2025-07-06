# Ansible: Automated Configuration and Deployment

This folder contains all automation for provisioning, configuring, and managing your self-hosted mail server (Docker Mailserver) on AWS EC2. Ansible handles all post-infrastructure steps, including package installation, Docker Mailserver deployment, S3-based backup/restore, Let's Encrypt SSL, and user management.

---

## What Does This Automation Do?

- Installs Docker, Docker Compose, Certbot, and dependencies
- Copies your customized `docker-compose.yml` and `.env` configuration files
- Restores previous mailserver data/config from S3 backup if available
- Requests and installs a Let's Encrypt SSL certificate for your domain
- Creates mail user accounts as defined in your variables
- Sets up weekly automatic SSL renewal with Certbot and a cron job
- Syncs updated mailserver data/config to S3 after provisioning

---

## How to Use

### 1. **Edit Inventory & Variables**

- Edit `inventory/hosts` to specify your EC2 instance’s public DNS or IP.
- Edit `group_vars/all.yaml` for all major settings:
  - S3 bucket name for backup/restore
  - Mail domain
  - Certbot contact email (for SSL)
  - User accounts and passwords

### 2. **Customize Docker Mailserver Environment**

- The `.env` file defines environment variables for Docker Mailserver.
- You may customize the environment using the official reference:  
  [Docker Mailserver Environment Variables](https://docker-mailserver.github.io/docker-mailserver/latest/config/environment/)
- Place your customized `.env` in `ansible/playbooks/roles/mailserver/files/` (or as specified in your playbook).

### 3. **AWS SES SMTP Credentials (Optional, for outgoing mail via SES)**

- To use AWS SES as your SMTP relay, you must create SMTP credentials.
- This is done by running the script provided in the [official AWS SES documentation](https://docs.aws.amazon.com/ses/latest/dg/smtp-credentials.html).  
  - The script will generate an SMTP username/password from an IAM user access key.
  - These credentials should be added to your `.env` file for Docker Mailserver.
- **This script is not included in this repo**—download it from AWS, and follow their instructions for usage.

### 4. **DNS Update Script (For EC2 IP Changes)**

- If you recreate or replace your EC2 instance, you must update the Route53 `mail.your-domain.com` A record.
- Use the provided script:
  ```sh
  cd ansible
  ./scripts/update-mail-a-record.sh
  ```
- This script requires AWS CLI access and updates the DNS to point to the new EC2 public IP.

### 5. **Run Ansible Playbook**

- From the `ansible/` folder:
  ```sh
  ansible-playbook -i inventory/hosts playbooks/deploy-mailserver.yml
  ```
- This will provision and configure everything as described above.

---

## Notes & Best Practices

- Ensure your EC2 IAM role has the necessary permissions for S3 and (if used) SES.
- S3 backup/restore is automatic; make sure your backup bucket exists and is correctly named in `all.yaml`.
- You can extend or modify user accounts in the `users` variable in `all.yaml`.
- For SSL, ensure your DNS A record for the mail domain points to the EC2 public IP **before** running Certbot via Ansible.

---

See the [project root README](../README.md) for an overview and prerequisites. For advanced configuration and troubleshooting, consult the official [Docker Mailserver documentation](https://docker-mailserver.github.io/docker-mailserver/latest/).