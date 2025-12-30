# k8s-infra

Infraestructura como Código (IaC) para provisionar y gestionar un clúster Kubernetes k3s en bare-metal.

## Descripción

Este proyecto automatiza el despliegue completo de un clúster k3s con un stack de producción que incluye:

- **k3s**: Distribución ligera de Kubernetes
- **Traefik**: Ingress controller con dashboard
- **cert-manager**: Certificados TLS automáticos con Let's Encrypt
- **Prometheus + Grafana**: Monitorización y dashboards
- **Loki + Promtail**: Agregación de logs
- **Redis**: Capa de caché

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                        Bare Metal                           │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                      k3s Cluster                      │  │
│  │                                                       │  │
│  │   ┌─────────────┐    ┌─────────────┐                  │  │
│  │   │   Traefik   │───▶│ Aplicaciones│                  │  │
│  │   │  (Ingress)  │    └─────────────┘                  │  │
│  │   └─────────────┘                                     │  │
│  │          │                                            │  │
│  │          ▼                                            │  │
│  │   ┌─────────────┐                                     │  │
│  │   │cert-manager │ ◀── Let's Encrypt                   │  │
│  │   └─────────────┘                                     │  │
│  │                                                       │  │
│  │   ┌─────────────┐    ┌─────────────┐    ┌──────────┐  │  │
│  │   │ Prometheus  │───▶│   Grafana   │    │  Redis   │  │  │
│  │   └─────────────┘    └─────────────┘    └──────────┘  │  │
│  │          │                                            │  │
│  │          ▼                                            │  │
│  │   ┌─────────────┐    ┌─────────────┐                  │  │
│  │   │    Loki     │◀───│  Promtail   │                  │  │
│  │   └─────────────┘    └─────────────┘                  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Estructura del Proyecto

```
k8s-infra/
├── ansible/                    # Instalación de k3s
│   ├── inventory.yml           # Configuración de hosts
│   ├── playbook.yml            # Playbook principal
│   └── roles/k3s/              # Role de instalación
│       ├── defaults/           # Variables por defecto
│       ├── handlers/           # Handlers de servicios
│       ├── tasks/              # Tareas de instalación
│       └── templates/          # Plantillas de configuración
│
├── terraform/                  # Provisión de componentes
│   ├── main.tf                 # Orquestación de módulos
│   ├── providers.tf            # Configuración de providers
│   ├── variables.tf            # Variables de entrada
│   ├── outputs.tf              # Valores de salida
│   └── modules/                # Módulos reutilizables
│       ├── cert-manager/       # Gestión de certificados
│       ├── traefik/            # Ingress controller
│       ├── monitoring/         # Prometheus + Grafana
│       ├── loki/               # Agregación de logs
│       └── redis/              # Caché
│
├── DEPLOY-APP.md               # Guía de despliegue de apps
├── USE-GUIDE.md                # Guía de uso de comandos
└── CLAUDE.md                   # Documentación para Claude Code
```

## Requisitos

- Servidor Linux con acceso SSH
- Ansible instalado localmente
- Terraform >= 1.0
- kubectl configurado

## Inicio Rápido

### 1. Instalar k3s con Ansible

```bash
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml
```

### 2. Configurar variables de Terraform

Crear `terraform/terraform.tfvars`:

```hcl
email               = "tu-email@ejemplo.com"
domain              = "tu-dominio.com"
grafana_admin_password = "tu-password-seguro"
redis_password      = "tu-password-redis"
```

### 3. Desplegar infraestructura con Terraform

```bash
cd terraform
terraform init
terraform apply
```

## Endpoints

| Servicio | URL |
|----------|-----|
| Traefik Dashboard | `https://traefik.{domain}` |
| Grafana | `https://grafana.{domain}` |
| Prometheus | Interno: `prometheus-server.monitoring.svc` |
| Loki | Interno: `loki.monitoring.svc.cluster.local:3100` |
| Redis | Interno: `redis-master.redis.svc.cluster.local:6379` |

## Configuración Modular

Cada componente puede habilitarse/deshabilitarse independientemente en `variables.tf`:

```hcl
enable_cert_manager = true
enable_traefik      = true
enable_monitoring   = true
enable_loki         = true
enable_redis        = true
```

## Documentación Adicional

- [USE-GUIDE.md](USE-GUIDE.md) - Guía de comandos Ansible y Terraform
- [DEPLOY-APP.md](DEPLOY-APP.md) - Guía para desplegar aplicaciones
