#!/bin/bash
set -euo pipefail

# Check arguments
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <service> <image_repo> <tag>"
  exit 1
fi

SERVICE="$1"
IMAGE_REPO="$2"
TAG="$3"

# Ensure required environment variables are set
: "${GIT_TOKEN:?GIT_TOKEN is not set. Please set it in GitHub Secrets}"
: "${GIT_USER:?GIT_USER is not set. Please set it in GitHub Secrets or env}"
: "${GIT_EMAIL:?GIT_EMAIL is not set. Please set it in GitHub Secrets or env}"

# Configure git
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_USER"

# Create temporary directory and ensure cleanup
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Clone the repo using token for authentication
git clone https://"$GIT_TOKEN"@github.com/akylgit/voting-app-azure-dev.git "$TEMP_DIR"

cd "$TEMP_DIR"

MANIFEST_FILE="k8s-specifications/$SERVICE-deployment.yaml"

# Check if manifest exists
if [ ! -f "$MANIFEST_FILE" ]; then
  echo "Error: $MANIFEST_FILE does not exist"
  exit 1
fi

# Update the image in deployment YAML
sed -i "s|^\(\s*image:\s*\).*|\1$IMAGE_REPO:$TAG|" "$MANIFEST_FILE"

# Stage changes
git add "$MANIFEST_FILE"

# Commit and push if there are changes
if git diff --cached --quiet; then
  echo "No changes to commit"
else
  git commit -m "Update $SERVICE deployment image to $TAG"
  git push
  echo "Changes pushed successfully!"
fi
