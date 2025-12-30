# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**k8s-infra** is an Infrastructure-as-Code project for provisioning and managing a bare-metal k3s Kubernetes cluster (`dev.jgcloud.es`). It uses Ansible for initial k3s installation and Terraform with Helm for deploying the Kubernetes stack.

## Common Commands

### Ansible (k3s Installation)
```bash
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml
```

### Terraform (Infrastructure Provisioning)
```bash
cd terraform
terraform init
terraform plan
terraform apply -var-file="terraform.tfvars"
terraform destroy
```

### Kubernetes Operations
```bash
kubectl apply -k k8s/                                    # Deploy with Kustomize
kubectl get pods -n <namespace>                          # Check pod status
kubectl logs -f deployment/<app> -n <namespace>          # View logs
kubectl rollout restart deployment/<app> -n <namespace>  # Restart deployment
```

## Architecture

### Deployment Flow
1. **Ansible** installs k3s on bare metal (with built-in Traefik disabled)
2. **Terraform** deploys Kubernetes components via Helm modules
3. Module dependencies: cert-manager → traefik → monitoring → loki

### Terraform Modules (`terraform/modules/`)
| Module | Purpose | Helm Chart |
|--------|---------|------------|
| cert-manager | Let's Encrypt TLS certificates | v1.16.2 |
| traefik | Ingress controller with dashboard | v33.2.1 |
| monitoring | Prometheus + Grafana stack | kube-prometheus-stack v68.3.0 |
| loki | Log aggregation | v6.24.0 + promtail v6.16.6 |
| redis | Caching layer (bitnami) | bitnami/redis |

### Ansible Structure (`ansible/`)
- `inventory.yml` - Host configuration and k3s variables
- `playbook.yml` - Main playbook
- `roles/k3s/` - k3s installation role (tasks, handlers, templates, defaults)

## Key Configuration

- **kubeconfig**: `/home/admin/.kube/config`
- **Domain pattern**: `*.dev.jgcloud.es` (wildcard DNS)
- **Traefik dashboard**: `https://traefik.{domain}`
- **Grafana**: `https://grafana.{domain}`
- **Loki endpoint**: `http://loki.monitoring.svc.cluster.local:3100`
- **Redis**: `redis://:password@redis-master.redis.svc.cluster.local:6379`

## Module Toggle System

All Terraform modules can be independently enabled/disabled via `enable_*` variables in `terraform/variables.tf`. Override defaults in `terraform.tfvars` (git-ignored for secrets).

## Important Notes

- k3s is configured with `--disable traefik` to allow custom Traefik deployment via Terraform
- Configurations are optimized for single bare-metal node (DaemonSet Traefik, single replica services)
- Sensitive values (passwords) should always be set in `terraform.tfvars`, not in version control
- DEPLOY-APP.md contains application deployment guide (in Spanish)
