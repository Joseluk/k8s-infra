output "cluster_issuers" {
  description = "Available ClusterIssuers"
  value       = var.enable_cert_manager ? module.cert_manager[0].cluster_issuers : []
}

output "traefik_dashboard_url" {
  description = "Traefik Dashboard URL"
  value       = var.enable_traefik ? module.traefik[0].dashboard_url : null
}

output "grafana_url" {
  description = "Grafana URL"
  value       = var.enable_monitoring ? module.monitoring[0].grafana_url : null
}

output "grafana_admin_user" {
  description = "Grafana admin username"
  value       = var.enable_monitoring ? module.monitoring[0].grafana_admin_user : null
}

output "loki_endpoint" {
  description = "Loki internal endpoint"
  value       = var.enable_loki ? module.loki[0].loki_endpoint : null
}

output "argocd_url" {
  description = "ArgoCD URL"
  value       = var.enable_argocd ? module.argocd[0].argocd_url : null
}

output "services" {
  description = "All service URLs"
  value = {
    traefik = var.enable_traefik ? "https://traefik.${var.domain}" : null
    grafana = var.enable_monitoring ? "https://grafana.${var.domain}" : null
    argocd  = var.enable_argocd ? "https://argocd.${var.domain}" : null
  }
}
