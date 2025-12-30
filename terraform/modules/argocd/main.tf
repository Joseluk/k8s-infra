# ArgoCD Module - GitOps Continuous Delivery

variable "domain" {
  description = "Domain for ArgoCD dashboard"
  type        = string
}

variable "admin_password" {
  description = "ArgoCD admin password (bcrypt hash)"
  type        = string
  sensitive   = true
  default     = ""
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.7.10"
  namespace        = "argocd"
  create_namespace = true
  timeout          = 600

  values = [<<-YAML
    global:
      domain: argocd.${var.domain}

    configs:
      params:
        server.insecure: true  # TLS handled by Traefik

    server:
      ingress:
        enabled: true
        ingressClassName: traefik
        annotations:
          cert-manager.io/cluster-issuer: letsencrypt-prod
        hosts:
          - argocd.${var.domain}
        tls:
          - secretName: argocd-tls
            hosts:
              - argocd.${var.domain}

    controller:
      resources:
        requests:
          cpu: 100m
          memory: 256Mi
        limits:
          cpu: 500m
          memory: 512Mi

    repoServer:
      resources:
        requests:
          cpu: 50m
          memory: 128Mi
        limits:
          cpu: 200m
          memory: 256Mi

    applicationSet:
      resources:
        requests:
          cpu: 50m
          memory: 64Mi
        limits:
          cpu: 100m
          memory: 128Mi

    notifications:
      enabled: false
  YAML
  ]
}

# Wait for ArgoCD to be ready
resource "null_resource" "wait_argocd" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd"
  }
}

output "argocd_url" {
  value = "https://argocd.${var.domain}"
}

output "argocd_namespace" {
  value = "argocd"
}
