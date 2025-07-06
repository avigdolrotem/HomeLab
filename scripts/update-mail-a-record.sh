#!/bin/bash
# Execute from parent folder using ./scripts/update-mail-a-record.sh
set -e

# Get the EC2 public IP from disposable outputs
EC2_IP=$(terraform -chdir=terraform/disposable output -raw mailserver_public_ip)

# Set your Route53 hosted zone ID and record name
ZONE_ID="your-route53-zone-id"
RECORD_NAME="mail.your-domain.com."

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
