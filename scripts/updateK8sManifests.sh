#!/bin/bash
set -euo pipefail

# Usage check
if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <image_repo> <tag> <service1> [service2 ...]"
  exit 1
fi

IMAGE_REPO="$1"
TAG="$2"
shift 2
SERVICES=("$@")

# Ensure required environment variables are set
: "${GIT_USER:?GIT_USER is not set}"
: "${GIT_EMAIL:?GIT_EMAIL is not set}"
: "${GIT_TOKEN:?GIT_TOKEN is not set}"

# Configure git
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_USER"

# Update manifests for each service
for SERVICE in "${SERVICES[@]}"; do
  MANIFEST_FILE="k8s-specifications/$SERVICE-deployment.yaml"

  if [ ! -f "$MANIFEST_FILE" ]; then
    echo "Warning: $MANIFEST_FILE does not exist, skipping."
    continue
  fi

  echo "Updating $MANIFEST_FILE to image $IMAGE_REPO:$TAG"
  sed -i "s|\(image:\s*\).*|\1$IMAGE_REPO:$TAG|" "$MANIFEST_FILE"
  git add "$MANIFEST_FILE"
done

# Commit and push changes
if git diff --cached --quiet; then
  echo "No changes to commit"
else
  git commit -m "Update deployment images to $TAG"
  git push https://$GIT_USER:$GIT_TOKEN@github.com/akylgit/voting-app-azure-dev.git HEAD:main
  echo "All updates pushed successfully!"
fi
