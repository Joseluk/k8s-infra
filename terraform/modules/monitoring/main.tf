variable "domain" {
  description = "Base domain for Grafana"
  type        = string
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin"  # Cambiar en producción
}

variable "kube_prometheus_version" {
  description = "kube-prometheus-stack chart version"
  type        = string
  default     = "68.3.0"
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.kube_prometheus_version
  namespace        = "monitoring"
  create_namespace = true

  # Timeout mayor porque despliega muchos componentes
  timeout = 600

  # Grafana config
  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "grafana.ingress.enabled"
    value = "true"
  }

  set {
    name  = "grafana.ingress.ingressClassName"
    value = "traefik"
  }

  set {
    name  = "grafana.ingress.hosts[0]"
    value = "grafana.${var.domain}"
  }

  set {
    name  = "grafana.ingress.tls[0].secretName"
    value = "grafana-tls"
  }

  set {
    name  = "grafana.ingress.tls[0].hosts[0]"
    value = "grafana.${var.domain}"
  }

  set {
    name  = "grafana.ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = "letsencrypt-prod"
  }

  # Prometheus config - sin ingress externo por seguridad
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "15d"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.cpu"
    value = "200m"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.memory"
    value = "512Mi"
  }

  # Alertmanager - deshabilitado por ahora
  set {
    name  = "alertmanager.enabled"
    value = "true"
  }

  # Desactivar componentes no necesarios en bare-metal
  set {
    name  = "kubeControllerManager.enabled"
    value = "false"
  }

  set {
    name  = "kubeScheduler.enabled"
    value = "false"
  }

  set {
    name  = "kubeProxy.enabled"
    value = "false"
  }

  set {
    name  = "kubeEtcd.enabled"
    value = "false"
  }

  # Recursos para operadores
  set {
    name  = "prometheusOperator.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "prometheusOperator.resources.requests.memory"
    value = "128Mi"
  }

  # Loki datasource para logs
  set {
    name  = "grafana.additionalDataSources[0].name"
    value = "Loki"
  }

  set {
    name  = "grafana.additionalDataSources[0].type"
    value = "loki"
  }

  set {
    name  = "grafana.additionalDataSources[0].url"
    value = "http://loki.monitoring.svc.cluster.local:3100"
  }

  set {
    name  = "grafana.additionalDataSources[0].access"
    value = "proxy"
  }

  set {
    name  = "grafana.additionalDataSources[0].isDefault"
    value = "false"
  }
}

output "grafana_url" {
  value = "https://grafana.${var.domain}"
}

output "grafana_admin_user" {
  value = "admin"
}
