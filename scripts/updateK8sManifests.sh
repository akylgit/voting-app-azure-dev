#!/bin/bash
set -euo pipefail

# Usage check
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <service> <image_repo> <tag>"
  exit 1
fi

SERVICE="$1"
IMAGE_REPO="$2"
TAG="$3"

# Git configuration
git config --global user.email "${GIT_EMAIL:-you@example.com}"
git config --global user.name "${GIT_USER:-Your Name}"

# Create temporary directory and ensure cleanup
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Clone repo
git clone https://"$GIT_TOKEN"@github.com/<your-org>/voting-app.git "$TEMP_DIR"
cd "$TEMP_DIR"

MANIFEST_FILE="k8s-specifications/$SERVICE-deployment.yaml"

if [ ! -f "$MANIFEST_FILE" ]; then
  echo "Error: $MANIFEST_FILE does not exist"
  exit 1
fi

# Update Kubernetes manifest image
sed -i "s|^\(\s*image:\s*\).*|\1$IMAGE_REPO:$TAG|" "$MANIFEST_FILE"

# Stage changes
git add "$MANIFEST_FILE"

# Commit and push only if there are changes
if git diff --cached --quiet; then
  echo "No changes to commit"
else
  git commit -m "Update $SERVICE deployment image to $TAG"
  git push
fi

echo "Update completed successfully!"
