#!/bin/bash
# Execute from parent folder using ./scripts/update-vaultwarden-a-record.sh
set -e

# Get the EC2 public IP from disposable outputs
EC2_IP=$(terraform -chdir=terraform/vaultwarden/disposable output -raw vaultwarden_public_ip)

# Set your Route53 hosted zone ID and record name
ZONE_ID="Z03200893DL2ZD0J62J86"
RECORD_NAME="passwords.avigdol.com."

# Update the A record via AWS CLI
aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch '{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "'$RECORD_NAME'",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{"Value": "'$EC2_IP'"}]
    }
  }]
}'

echo "Updated $RECORD_NAME A record in Route53 to $EC2_IP"
