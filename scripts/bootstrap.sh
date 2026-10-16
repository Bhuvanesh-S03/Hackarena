#!/usr/bin/env bash
# One-time setup: Terraform state bucket + ECR repo. Usage: ./scripts/bootstrap.sh <unique-bucket-name> [region]
set -euo pipefail
BUCKET=${1:?bucket name required}
REGION=${2:-ap-south-1}
aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"
aws s3api put-bucket-versioning --bucket "$BUCKET" --versioning-configuration Status=Enabled
aws ecr create-repository --repository-name arena --region "$REGION"
echo "Done. State bucket: $BUCKET"
