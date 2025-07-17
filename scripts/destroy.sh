#!/bin/bash
set -e
cd infrastructure/terraform/environments/dev
terraform destroy -auto-approve