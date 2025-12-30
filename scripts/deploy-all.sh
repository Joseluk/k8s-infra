#!/bin/bash
# Deploy all CertPrep apps using Kustomize
# Usage: ./deploy-all.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"

SITES="awsprep azureprep gcpprep ciscoprep comptiprep pmpprep scrumprep securityprep devopsprep linuxprep networkprep itfundprep cloudprep"

echo "Deploying all CertPrep apps..."
echo "=============================="

for site in $SITES; do
  echo ""
  echo ">>> Deploying $site..."
  kubectl apply -k "$INFRA_DIR/apps/overlays/$site"
done

echo ""
echo "=============================="
echo "All deployments complete!"
echo ""
echo "Checking pod status..."
kubectl get pods -n default | grep -E "prep-(web|db)"
