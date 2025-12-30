#!/bin/bash
# Deploy a single CertPrep app using Kustomize
# Usage: ./deploy-app.sh <site_id>
# Example: ./deploy-app.sh awsprep

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"

if [ -z "$1" ]; then
  echo "Usage: $0 <site_id>"
  echo "Available sites:"
  ls -1 "$INFRA_DIR/apps/overlays" | tr '\n' ' '
  echo ""
  exit 1
fi

SITE="$1"
OVERLAY_PATH="$INFRA_DIR/apps/overlays/$SITE"

if [ ! -d "$OVERLAY_PATH" ]; then
  echo "Error: Overlay not found for site '$SITE'"
  echo "Available sites:"
  ls -1 "$INFRA_DIR/apps/overlays"
  exit 1
fi

echo "Deploying $SITE..."
kubectl apply -k "$OVERLAY_PATH"

echo ""
echo "Deployment complete. Checking status..."
kubectl get pods -l app="${SITE}-web" -n default
kubectl get pods -l app="${SITE}-db" -n default
