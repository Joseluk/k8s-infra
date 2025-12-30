#!/bin/bash
# Build Docker image and deploy a CertPrep app
# Usage: ./build-and-deploy.sh <site_id> <app_path>
# Example: ./build-and-deploy.sh awsprep /home/admin/claude/awsprep

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <site_id> <app_path>"
  echo "Example: $0 awsprep /home/admin/claude/awsprep"
  exit 1
fi

SITE="$1"
APP_PATH="$2"

if [ ! -d "$APP_PATH" ]; then
  echo "Error: App path not found: $APP_PATH"
  exit 1
fi

echo "Building $SITE from $APP_PATH..."
echo "================================"

# Build Docker image
echo "1. Building Docker image..."
sudo docker build -t "$SITE:latest" "$APP_PATH"

# Import to k3s containerd
echo "2. Importing image to k3s..."
sudo docker save "$SITE:latest" | sudo k3s ctr images import -

# Deploy using Kustomize
echo "3. Deploying to cluster..."
kubectl apply -k "$INFRA_DIR/apps/overlays/$SITE"

# Restart deployment to pick up new image
echo "4. Restarting deployment..."
kubectl rollout restart deployment/"$SITE-web" -n default

echo ""
echo "================================"
echo "Build and deploy complete!"
echo ""
echo "Waiting for rollout..."
kubectl rollout status deployment/"$SITE-web" -n default --timeout=120s
