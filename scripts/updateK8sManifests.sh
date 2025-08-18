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

# Ensure required environment variables are set
: "${GIT_USER:?GIT_USER is not set}"
: "${GIT_EMAIL:?GIT_EMAIL is not set}"

# Configure git
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_USER"

# Working directory is already the repo (GitHub Actions checkout)
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
