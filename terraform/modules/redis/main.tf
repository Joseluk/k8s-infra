resource "helm_release" "redis" {
  name             = "redis"
  namespace        = "redis"
  create_namespace = true
  repository       = "oci://registry-1.docker.io/bitnamicharts"
  chart            = "redis"
  wait             = true
  timeout          = 600

  values = [<<-EOT
    architecture: standalone

    auth:
      enabled: true
      password: "${var.redis_password}"

    master:
      persistence:
        enabled: true
        size: 2Gi
        storageClass: "local-path"

      resources:
        requests:
          memory: 128Mi
          cpu: 100m
        limits:
          memory: 256Mi
          cpu: 250m

    replica:
      replicaCount: 0

    metrics:
      enabled: false
  EOT
  ]
}

# Create a service for internal access
resource "kubectl_manifest" "redis_internal_service" {
  depends_on = [helm_release.redis]

  yaml_body = <<-YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: redis-internal
      namespace: redis
    spec:
      type: ClusterIP
      ports:
        - port: 6379
          targetPort: 6379
          protocol: TCP
          name: redis
      selector:
        app.kubernetes.io/instance: redis
        app.kubernetes.io/name: redis
  YAML
}

# Output the connection URL for apps
output "redis_url" {
  description = "Redis connection URL for apps"
  value       = "redis://:${var.redis_password}@redis-master.redis.svc.cluster.local:6379"
  sensitive   = true
}

output "redis_host" {
  description = "Redis host"
  value       = "redis-master.redis.svc.cluster.local"
}

output "redis_port" {
  description = "Redis port"
  value       = 6379
}
