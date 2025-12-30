# Guía de Uso - Comandos Ansible y Terraform

Esta guía contiene los comandos más importantes para gestionar la infraestructura k3s.

## Ansible

### Comandos Básicos

```bash
# Ejecutar playbook completo (instalar k3s)
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml

# Ejecutar con verbose para debug
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml -v
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml -vvv  # Más detalle

# Verificar sintaxis sin ejecutar
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml --syntax-check

# Simulación (dry-run)
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml --check

# Ejecutar solo tareas con un tag específico
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml --tags "install"

# Saltar tareas con un tag específico
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml --skip-tags "config"

# Listar todas las tareas
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml --list-tasks

# Listar hosts del inventario
ansible-inventory -i ansible/inventory.yml --list
```

### Comandos Ad-Hoc

```bash
# Ping a todos los hosts
ansible -i ansible/inventory.yml all -m ping

# Ejecutar comando en hosts
ansible -i ansible/inventory.yml all -m shell -a "kubectl get nodes"

# Ver facts de un host
ansible -i ansible/inventory.yml all -m setup
```

---

## Terraform

### Inicialización

```bash
cd terraform

# Inicializar Terraform (descargar providers y módulos)
terraform init

# Reinicializar y actualizar providers
terraform init -upgrade

# Inicializar para un backend específico
terraform init -backend-config="path/to/backend.hcl"
```

### Planificación

```bash
# Ver plan de cambios
terraform plan

# Plan con archivo de variables
terraform plan -var-file="terraform.tfvars"

# Guardar plan a archivo
terraform plan -out=plan.tfplan

# Plan solo para un módulo específico
terraform plan -target=module.traefik

# Plan para destruir
terraform plan -destroy
```

### Aplicación

```bash
# Aplicar cambios (con confirmación)
terraform apply

# Aplicar con archivo de variables
terraform apply -var-file="terraform.tfvars"

# Aplicar plan guardado (sin confirmación)
terraform apply plan.tfplan

# Aplicar sin confirmación interactiva
terraform apply -auto-approve

# Aplicar solo un módulo específico
terraform apply -target=module.monitoring

# Aplicar con variable inline
terraform apply -var="enable_redis=false"
```

### Destrucción

```bash
# Destruir toda la infraestructura (con confirmación)
terraform destroy

# Destruir sin confirmación
terraform destroy -auto-approve

# Destruir solo un recurso específico
terraform destroy -target=module.redis

# Destruir múltiples recursos
terraform destroy -target=module.loki -target=module.redis
```

### Estado

```bash
# Ver estado actual
terraform show

# Listar recursos en el estado
terraform state list

# Ver detalle de un recurso
terraform state show module.traefik.helm_release.traefik

# Mover recurso en el estado
terraform state mv module.old module.new

# Eliminar recurso del estado (sin destruir)
terraform state rm module.redis

# Importar recurso existente al estado
terraform import module.traefik.helm_release.traefik traefik/traefik
```

### Validación y Formato

```bash
# Validar configuración
terraform validate

# Formatear archivos .tf
terraform fmt

# Formatear recursivamente
terraform fmt -recursive

# Verificar formato (CI/CD)
terraform fmt -check
```

### Outputs

```bash
# Ver todos los outputs
terraform output

# Ver output específico
terraform output grafana_url

# Output en formato JSON
terraform output -json
```

### Workspace (Entornos)

```bash
# Listar workspaces
terraform workspace list

# Crear nuevo workspace
terraform workspace new staging

# Cambiar de workspace
terraform workspace select production

# Mostrar workspace actual
terraform workspace show
```

---

## Flujos de Trabajo Comunes

### Despliegue Inicial Completo

```bash
# 1. Instalar k3s
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml

# 2. Verificar k3s
kubectl get nodes

# 3. Inicializar y aplicar Terraform
cd terraform
terraform init
terraform apply -var-file="terraform.tfvars"
```

### Actualizar un Componente

```bash
cd terraform

# Actualizar solo Traefik
terraform apply -target=module.traefik

# Actualizar solo monitorización
terraform apply -target=module.monitoring
```

### Reinstalar k3s

```bash
# Desinstalar k3s (ejecutar en el servidor)
/usr/local/bin/k3s-uninstall.sh

# Reinstalar con Ansible
ansible-playbook -i ansible/inventory.yml ansible/playbook.yml
```

### Debugging

```bash
# Habilitar logs detallados de Terraform
export TF_LOG=DEBUG
terraform apply

# Ver logs de un provider específico
export TF_LOG_PROVIDER=DEBUG

# Desactivar logs
unset TF_LOG
```

---

## Variables de Entorno Útiles

```bash
# Terraform
export TF_VAR_domain="mi-dominio.com"          # Variable de Terraform
export TF_LOG=INFO                              # Nivel de log
export TF_INPUT=false                           # Desactivar input interactivo

# Ansible
export ANSIBLE_HOST_KEY_CHECKING=False          # Ignorar verificación SSH
export ANSIBLE_STDOUT_CALLBACK=yaml             # Output en formato YAML
```
