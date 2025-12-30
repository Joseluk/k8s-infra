variable "domain" {
  description = "Base domain for Traefik dashboard"
  type        = string
}

variable "traefik_version" {
  description = "Traefik Helm chart version"
  type        = string
  default     = "33.2.1"
}

resource "helm_release" "traefik" {
  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  version          = var.traefik_version
  namespace        = "traefik"
  create_namespace = true

  values = [<<-YAML
    # Deployment como DaemonSet sin hostNetwork
    deployment:
      kind: DaemonSet

    # k3s tiene servicelb integrado, usamos LoadBalancer
    service:
      type: LoadBalancer
      annotations:
        # k3s servicelb usará los puertos 80/443 directamente
        metallb.universe.tf/allow-shared-ip: traefik

    # Puertos estándar
    ports:
      web:
        port: 80
        exposedPort: 80
      websecure:
        port: 443
        exposedPort: 443

    ingressRoute:
      dashboard:
        enabled: true
        matchRule: Host(`traefik.${var.domain}`)
        entryPoints:
          - websecure
        tls:
          secretName: traefik-dashboard-tls

    api:
      dashboard: true
      insecure: true

    logs:
      general:
        level: INFO
      access:
        enabled: true

    resources:
      requests:
        cpu: 100m
        memory: 128Mi
  YAML
  ]
}

# Certificate para Traefik dashboard
resource "kubectl_manifest" "traefik_dashboard_cert" {
  depends_on = [helm_release.traefik]

  yaml_body = <<-YAML
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: traefik-dashboard-tls
      namespace: traefik
    spec:
      secretName: traefik-dashboard-tls
      issuerRef:
        name: letsencrypt-prod
        kind: ClusterIssuer
      dnsNames:
        - traefik.${var.domain}
  YAML
}

output "dashboard_url" {
  value = "https://traefik.${var.domain}"
}
