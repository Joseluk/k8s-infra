# Cert-Manager - debe ir primero
module "cert_manager" {
  source = "./modules/cert-manager"
  count  = var.enable_cert_manager ? 1 : 0

  email = var.email
}

# Traefik Ingress Controller
module "traefik" {
  source = "./modules/traefik"
  count  = var.enable_traefik ? 1 : 0

  domain = var.domain

  depends_on = [module.cert_manager]
}

# Prometheus + Grafana
module "monitoring" {
  source = "./modules/monitoring"
  count  = var.enable_monitoring ? 1 : 0

  domain                 = var.domain
  grafana_admin_password = var.grafana_admin_password

  depends_on = [module.traefik]
}

# Loki + Promtail
module "loki" {
  source = "./modules/loki"
  count  = var.enable_loki ? 1 : 0

  depends_on = [module.monitoring]
}

# Redis - for caching
module "redis" {
  source = "./modules/redis"
  count  = var.enable_redis ? 1 : 0

  redis_password = var.redis_password

  depends_on = [module.cert_manager]
}

# ArgoCD - GitOps CD
module "argocd" {
  source = "./modules/argocd"
  count  = var.enable_argocd ? 1 : 0

  domain = var.domain

  depends_on = [module.traefik]
}
