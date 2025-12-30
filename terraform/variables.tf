variable "kubeconfig_path" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "/home/admin/.kube/config"
}

variable "email" {
  description = "Email for Let's Encrypt certificates"
  type        = string
}

variable "domain" {
  description = "Base domain for the cluster"
  type        = string
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "enable_cert_manager" {
  description = "Enable cert-manager"
  type        = bool
  default     = true
}

variable "enable_traefik" {
  description = "Enable Traefik ingress controller"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable Prometheus + Grafana monitoring stack"
  type        = bool
  default     = true
}

variable "enable_loki" {
  description = "Enable Loki logging stack"
  type        = bool
  default     = true
}

variable "enable_redis" {
  description = "Enable Redis for caching"
  type        = bool
  default     = true
}

variable "redis_password" {
  description = "Redis password"
  type        = string
  sensitive   = true
  default     = "cloudprep-redis-2024"
}

variable "enable_argocd" {
  description = "Enable ArgoCD GitOps CD"
  type        = bool
  default     = true
}
