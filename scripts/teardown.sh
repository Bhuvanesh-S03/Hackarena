#!/usr/bin/env bash
# Manual full cleanup (alternative to the 'destroy' workflow). Usage: ./scripts/teardown.sh <bucket> [region]
set -euo pipefail
BUCKET=${1:?bucket}; REGION=${2:-ap-south-1}
cd "$(dirname "$0")/../terraform"
terraform init -input=false -backend-config="bucket=$BUCKET" -backend-config="key=arena.tfstate" -backend-config="region=$REGION"
terraform destroy -auto-approve -var 'team_names=[]' -var 'image_tag=x'
aws ecr delete-repository --repository-name arena --force --region "$REGION"
echo "Optional: delete the state bucket '$BUCKET' manually."
