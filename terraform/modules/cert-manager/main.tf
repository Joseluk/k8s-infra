variable "email" {
  description = "Email for Let's Encrypt"
  type        = string
}

variable "cert_manager_version" {
  description = "cert-manager chart version"
  type        = string
  default     = "v1.16.2"
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_version
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "crds.enabled"
    value = "true"
  }

  set {
    name  = "prometheus.enabled"
    value = "false"
  }
}

resource "kubectl_manifest" "cluster_issuer_staging" {
  depends_on = [helm_release.cert_manager]

  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-staging
    spec:
      acme:
        server: https://acme-staging-v02.api.letsencrypt.org/directory
        email: ${var.email}
        privateKeySecretRef:
          name: letsencrypt-staging-key
        solvers:
          - http01:
              ingress:
                class: traefik
  YAML
}

resource "kubectl_manifest" "cluster_issuer_prod" {
  depends_on = [helm_release.cert_manager]

  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
      name: letsencrypt-prod
    spec:
      acme:
        server: https://acme-v02.api.letsencrypt.org/directory
        email: ${var.email}
        privateKeySecretRef:
          name: letsencrypt-prod-key
        solvers:
          - http01:
              ingress:
                class: traefik
  YAML
}

output "cluster_issuers" {
  value = ["letsencrypt-staging", "letsencrypt-prod"]
}
