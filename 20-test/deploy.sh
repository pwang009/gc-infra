#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="${APP_NAME:-gc-api}"
ENV_NAME="${ENV_NAME:-gc-api-dev}"
VERSION_LABEL="${VERSION_LABEL:-test-api-$(date +%Y%m%d%H%M%S)}"
BUCKET_NAME="${BUCKET_NAME:-elasticbeanstalk-us-west-2-339087217430}"
S3_KEY="${S3_KEY:-${VERSION_LABEL}.zip}"
ARCHIVE_NAME="${ARCHIVE_NAME:-${VERSION_LABEL}.zip}"

rm -f "$ARCHIVE_NAME"
zip -r "$ARCHIVE_NAME" application.py requirements.txt test_app.py Procfile

aws s3 cp "$ARCHIVE_NAME" "s3://${BUCKET_NAME}/${S3_KEY}"

aws elasticbeanstalk create-application-version \
  --application-name "$APP_NAME" \
  --version-label "$VERSION_LABEL" \
  --source-bundle "S3Bucket=${BUCKET_NAME},S3Key=${S3_KEY}"

aws elasticbeanstalk update-environment \
  --application-name "$APP_NAME" \
  --environment-name "$ENV_NAME" \
  --version-label "$VERSION_LABEL"

echo "Deployment started for ${APP_NAME}/${ENV_NAME} using version ${VERSION_LABEL}"
