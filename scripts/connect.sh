#!/bin/bash
# scripts/connect.sh - Connect to HomeLab EC2 instance

cd infrastructure/terraform/environments/dev
INSTANCE_IP=$(terraform output -raw instance_public_ip)
ssh -i homelab-key.pem ubuntu@$INSTANCE_IP