variable "loki_version" {
  description = "Loki Helm chart version"
  type        = string
  default     = "6.24.0"
}

variable "promtail_version" {
  description = "Promtail Helm chart version"
  type        = string
  default     = "6.16.6"
}

# Loki - almacenamiento de logs
resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  version          = var.loki_version
  namespace        = "monitoring"
  create_namespace = true

  timeout = 600

  # Deshabilitar autenticación multi-tenant (single-tenant setup)
  set {
    name  = "loki.auth_enabled"
    value = "false"
  }

  # Modo single binary (simple, para un solo nodo)
  set {
    name  = "deploymentMode"
    value = "SingleBinary"
  }

  set {
    name  = "singleBinary.replicas"
    value = "1"
  }

  # Deshabilitar backend y read/write separados
  set {
    name  = "backend.replicas"
    value = "0"
  }

  set {
    name  = "read.replicas"
    value = "0"
  }

  set {
    name  = "write.replicas"
    value = "0"
  }

  # Storage filesystem local
  set {
    name  = "loki.storage.type"
    value = "filesystem"
  }

  set {
    name  = "loki.commonConfig.replication_factor"
    value = "1"
  }

  set {
    name  = "loki.schemaConfig.configs[0].from"
    value = "2024-01-01"
  }

  set {
    name  = "loki.schemaConfig.configs[0].store"
    value = "tsdb"
  }

  set {
    name  = "loki.schemaConfig.configs[0].object_store"
    value = "filesystem"
  }

  set {
    name  = "loki.schemaConfig.configs[0].schema"
    value = "v13"
  }

  set {
    name  = "loki.schemaConfig.configs[0].index.prefix"
    value = "index_"
  }

  set {
    name  = "loki.schemaConfig.configs[0].index.period"
    value = "24h"
  }

  # Deshabilitar gateway
  set {
    name  = "gateway.enabled"
    value = "false"
  }

  # Recursos
  set {
    name  = "singleBinary.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "singleBinary.resources.requests.memory"
    value = "256Mi"
  }

  # Retención de logs
  set {
    name  = "loki.limits_config.retention_period"
    value = "168h"
  }

  # Deshabilitar minio
  set {
    name  = "minio.enabled"
    value = "false"
  }

  # Test deshabilitado
  set {
    name  = "test.enabled"
    value = "false"
  }

  # Lokicanary deshabilitado
  set {
    name  = "lokiCanary.enabled"
    value = "false"
  }
}

# Promtail - agente que recolecta logs
resource "helm_release" "promtail" {
  name             = "promtail"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "promtail"
  version          = var.promtail_version
  namespace        = "monitoring"
  create_namespace = true

  depends_on = [helm_release.loki]

  set {
    name  = "config.clients[0].url"
    value = "http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
  }

  set {
    name  = "resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "resources.requests.memory"
    value = "64Mi"
  }
}

output "loki_endpoint" {
  value = "http://loki.monitoring.svc.cluster.local:3100"
}
