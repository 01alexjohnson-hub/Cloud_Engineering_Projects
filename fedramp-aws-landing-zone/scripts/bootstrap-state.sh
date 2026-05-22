#!/bin/bash
# -----------------------------------------------------------------------------
# Bootstrap Terraform Remote State
# Creates the S3 bucket and DynamoDB table for state management
# Run this ONCE before your first terraform init
# -----------------------------------------------------------------------------
# Usage: ./scripts/bootstrap-state.sh
# Prerequisites: AWS CLI configured with appropriate credentials
# -----------------------------------------------------------------------------

set -euo pipefail

BUCKET_NAME="fedramp-landing-zone-tfstate"
TABLE_NAME="fedramp-landing-zone-tflock"
REGION="us-east-1"

echo "=== Bootstrapping Terraform Remote State ==="
echo "Region: ${REGION}"
echo "Bucket: ${BUCKET_NAME}"
echo "Table:  ${TABLE_NAME}"
echo ""

# Create S3 bucket for state
echo "[1/4] Creating S3 bucket..."
aws s3api create-bucket \
  --bucket "${BUCKET_NAME}" \
  --region "${REGION}" \
  2>/dev/null || echo "  Bucket already exists, continuing..."

# Enable versioning (protects against accidental state deletion)
echo "[2/4] Enabling versioning..."
aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

# Enable server-side encryption (NIST 800-53: SC-28)
echo "[3/4] Enabling encryption..."
aws s3api put-bucket-encryption \
  --bucket "${BUCKET_NAME}" \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        },
        "BucketKeyEnabled": true
      }
    ]
  }'

# Block all public access (NIST 800-53: AC-4)
echo "[3.5/4] Blocking public access..."
aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration '{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
  }'

# Create DynamoDB table for state locking
echo "[4/4] Creating DynamoDB table for state locking..."
aws dynamodb create-table \
  --table-name "${TABLE_NAME}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${REGION}" \
  2>/dev/null || echo "  Table already exists, continuing..."

echo ""
echo "=== Bootstrap Complete ==="
echo "You can now run: terraform init"
echo ""
echo "Free tier note:"
echo "  - S3: covered under 5GB free tier"
echo "  - DynamoDB: covered under 25GB free tier (PAY_PER_REQUEST)"
echo "  - Versioning adds minimal storage for state file changes"
