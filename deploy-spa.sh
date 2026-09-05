#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: deploy-spa.sh
# Purpose: Build Vite SPA, upload to S3, and invalidate CloudFront CDN cache
# Usage: ./deploy-spa.sh [SPA_DIR] [ENV]
# Example: ./deploy-spa.sh ../gc-frontend dev
# ==============================================================================

SPA_DIR="${1:-.}"
ENV="${2:-dev}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_MODULE_DIR="${SCRIPT_DIR}/03-app-v3"

echo "=========================================="
echo " Starting Vite SPA Deployment"
echo " Environment : ${ENV}"
echo " SPA Directory: ${SPA_DIR}"
echo "=========================================="

# 0. Ensure Node and npm are available in PATH (load NVM if installed)
if ! command -v npm &> /dev/null; then
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [ -s "$NVM_DIR/nvm.sh" ]; then
    set +e
    \. "$NVM_DIR/nvm.sh"
    nvm use 22 > /dev/null 2>&1 || nvm use 20 > /dev/null 2>&1 || nvm use 18 > /dev/null 2>&1 || nvm use node > /dev/null 2>&1
    set -e
  fi
fi

if ! command -v npm &> /dev/null; then
  LATEST_NODE_BIN=$(find "${HOME}/.nvm/versions/node" -maxdepth 2 -name "bin" 2>/dev/null | sort -V | tail -n 1 || true)
  if [ -n "$LATEST_NODE_BIN" ] && [ -d "$LATEST_NODE_BIN" ]; then
    export PATH="${LATEST_NODE_BIN}:${PATH}"
  fi
fi

if ! command -v npm &> /dev/null; then
  echo "Error: 'npm' command not found. Please ensure Node.js / npm is installed and in your PATH."
  exit 1
fi

# 1. Resolve S3 Bucket and CloudFront Distribution ID
if [ -z "${S3_BUCKET:-}" ] || [ -z "${CDN_DIST_ID:-}" ]; then
  if [ -d "${APP_MODULE_DIR}" ] && command -v terraform &> /dev/null; then
    echo "Resolving S3 bucket and CloudFront distribution ID from Terraform outputs..."
    S3_BUCKET="${S3_BUCKET:-$(terraform -chdir="${APP_MODULE_DIR}" output -raw s3_bucket_name 2>/dev/null || true)}"
    CDN_DIST_ID="${CDN_DIST_ID:-$(terraform -chdir="${APP_MODULE_DIR}" output -raw cloudfront_distribution_id 2>/dev/null || true)}"
  fi
fi

if [ -z "${S3_BUCKET:-}" ]; then
  echo "Error: S3_BUCKET is not set and could not be retrieved from Terraform."
  echo "Please export S3_BUCKET or run terraform apply in 03-app-v3 first."
  exit 1
fi

if [ -z "${CDN_DIST_ID:-}" ]; then
  echo "Error: CDN_DIST_ID is not set and could not be retrieved from Terraform."
  echo "Please export CDN_DIST_ID or run terraform apply in 03-app-v3 first."
  exit 1
fi

echo " Target S3 Bucket : ${S3_BUCKET}"
echo " CloudFront Dist ID: ${CDN_DIST_ID}"
echo "------------------------------------------"

# 2. Navigate to SPA directory and build
echo "=== 1/3 Navigating to SPA and Building ==="
if [ ! -d "${SPA_DIR}" ]; then
  echo "Error: Directory '${SPA_DIR}' does not exist."
  exit 1
fi

cd "${SPA_DIR}"
echo "Current working directory: $(pwd)"

if [ ! -f "package.json" ]; then
  echo "Error: No package.json found in $(pwd)."
  exit 1
fi

if [ ! -d "node_modules" ]; then
  echo "Installing dependencies..."
  npm install
fi

echo "Running production build..."
npm run build

if [ ! -d "dist" ]; then
  echo "Error: Build output directory 'dist' not found."
  exit 1
fi

# 3. Sync to S3
echo "=== 2/3 Syncing build artifacts to S3 (${S3_BUCKET}) ==="

# Upload immutable assets (JS, CSS, images) with 1-year cache TTL
if [ -d "dist/assets" ]; then
  echo "Uploading hashed static assets with immutable cache headers..."
  aws s3 sync dist/assets/ "s3://${S3_BUCKET}/assets/" \
    --cache-control "public, max-age=31536000, immutable" \
    --delete
fi

# Upload remaining files (including index.html) with no-cache headers
echo "Uploading index.html and root files with no-cache headers..."
aws s3 sync dist/ "s3://${S3_BUCKET}/" \
  --cache-control "no-cache, no-store, must-revalidate" \
  --delete

# Return to original script directory for subsequent operations if needed
cd "${SCRIPT_DIR}"

# 4. Invalidate CloudFront CDN Cache
echo "=== 3/3 Invalidating CloudFront cache (${CDN_DIST_ID}) ==="
INVALIDATION_ID=$(aws cloudfront create-invalidation \
  --distribution-id "${CDN_DIST_ID}" \
  --paths "/*" \
  --query "Invalidation.Id" \
  --output text)

echo "Created invalidation: ${INVALIDATION_ID}"
echo "Waiting for CloudFront invalidation to complete..."
aws cloudfront wait invalidation-completed \
  --distribution-id "${CDN_DIST_ID}" \
  --id "${INVALIDATION_ID}"

echo "=========================================="
echo " Deployment completed successfully!"
echo " App URL: https://app.${ENV}.goodconnex.com"
echo "=========================================="
