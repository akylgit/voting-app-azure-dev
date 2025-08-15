#!/bin/bash
set -e

# Arguments: $1 = service (vote/worker), $2 = image repo, $3 = tag
SERVICE=$1
IMAGE_REPO=$2
TAG=$3

# Git configuration
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_USER"

# Clone repo
git clone https://$GIT_TOKEN@github.com/<your-org>/voting-app.git /tmp/temp_repo
cd /tmp/temp_repo

# Update Kubernetes manifest
sed -i "s|image:.*|image: $IMAGE_REPO:$TAG|g" k8s-specifications/$SERVICE-deployment.yaml

# Stage changes
git add k8s-specifications/$SERVICE-deployment.yaml

# Commit and push only if there are changes
if git diff --cached --quiet; then
  echo "No changes to commit"
else
  git commit -m "Update $SERVICE deployment image to $TAG"
  git push
fi

# Cleanup
rm -rf /tmp/temp_repo
