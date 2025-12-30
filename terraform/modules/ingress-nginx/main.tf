variable "ingress_nginx_version" {
  description = "ingress-nginx chart version"
  type        = string
  default     = "4.12.0"
}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.ingress_nginx_version
  namespace        = "ingress-nginx"
  create_namespace = true

  # Configuración para bare-metal con hostNetwork
  set {
    name  = "controller.hostNetwork"
    value = "true"
  }

  set {
    name  = "controller.hostPort.enabled"
    value = "true"
  }

  set {
    name  = "controller.kind"
    value = "DaemonSet"
  }

  set {
    name  = "controller.service.type"
    value = "ClusterIP"
  }

  # Habilitar proxy protocol si hay un balanceador externo
  set {
    name  = "controller.config.use-forwarded-headers"
    value = "true"
  }

  # Optimizaciones
  set {
    name  = "controller.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "128Mi"
  }
}

output "ingress_class" {
  value = "nginx"
}
