# Guía de Despliegue de Aplicaciones en k3s

Esta guía documenta el proceso para desplegar una nueva aplicación en el cluster k3s de `dev.jgcloud.es`.

## Requisitos Previos

- Acceso al servidor con `kubectl` configurado
- Docker instalado para construir imágenes
- Aplicación con Dockerfile de producción

## Estructura de Archivos

Cada aplicación debe tener un directorio `k8s/` con los siguientes manifiestos:

```
mi-app/
├── Dockerfile
├── k8s/
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── kustomization.yaml
└── ... (código fuente)
```

## Paso 1: Crear Dockerfile de Producción

Ejemplo para Next.js con Bun:

```dockerfile
# Build stage
FROM oven/bun:1.1.42-alpine AS builder
WORKDIR /app

COPY package.json bun.lock* ./
COPY apps/web/package.json ./apps/web/
# ... copiar otros package.json de monorepo

RUN bun install

COPY . .

ARG NEXT_PUBLIC_APP_URL
ENV NEXT_PUBLIC_APP_URL=$NEXT_PUBLIC_APP_URL
ENV NODE_ENV=production

WORKDIR /app/apps/web
RUN bun run build

# Production stage
FROM oven/bun:1.1.42-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

COPY --from=builder /app/apps/web/.next/standalone ./
COPY --from=builder /app/apps/web/.next/static ./apps/web/.next/static

RUN chown -R nextjs:nodejs /app
USER nextjs

EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

WORKDIR /app/apps/web
CMD ["bun", "server.js"]
```

## Paso 2: Crear Manifiestos de Kubernetes

### namespace.yaml
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: mi-app
```

### configmap.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mi-app-config
  namespace: mi-app
data:
  NEXT_PUBLIC_APP_URL: "https://mi-app.dev.jgcloud.es"
  NODE_ENV: "production"
```

### secret.yaml
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mi-app-secrets
  namespace: mi-app
type: Opaque
stringData:
  DATABASE_URL: "postgresql://..."
  API_KEY: "..."
```

### deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mi-app
  namespace: mi-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mi-app
  template:
    metadata:
      labels:
        app: mi-app
    spec:
      containers:
        - name: web
          image: mi-app:latest
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 3000
          envFrom:
            - configMapRef:
                name: mi-app-config
            - secretRef:
                name: mi-app-secrets
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
          livenessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 5
```

### service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mi-app
  namespace: mi-app
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 3000
  selector:
    app: mi-app
```

### ingress.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mi-app
  namespace: mi-app
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: traefik
  tls:
    - hosts:
        - mi-app.dev.jgcloud.es
      secretName: mi-app-tls
  rules:
    - host: mi-app.dev.jgcloud.es
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: mi-app
                port:
                  number: 80
```

### kustomization.yaml
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: mi-app
resources:
  - namespace.yaml
  - configmap.yaml
  - secret.yaml
  - deployment.yaml
  - service.yaml
  - ingress.yaml
```

## Paso 3: Construir la Imagen Docker

```bash
cd /path/to/mi-app

# Construir con build args si es necesario
sudo docker build \
  --build-arg NEXT_PUBLIC_APP_URL="https://mi-app.dev.jgcloud.es" \
  -t mi-app:latest \
  -f Dockerfile .
```

## Paso 4: Importar Imagen a k3s

k3s usa containerd, no Docker. Para usar imágenes locales:

```bash
# Exportar de Docker e importar a k3s containerd
sudo docker save mi-app:latest | sudo k3s ctr images import -
```

## Paso 5: Desplegar en Kubernetes

```bash
# Usando kustomize
kubectl apply -k k8s/

# O aplicar archivos individualmente
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
```

## Paso 6: Verificar Despliegue

```bash
# Ver pods
kubectl get pods -n mi-app

# Ver logs
kubectl logs -f deployment/mi-app -n mi-app

# Ver certificado TLS
kubectl get certificate -n mi-app

# Ver ingress
kubectl get ingress -n mi-app

# Test HTTP
curl -I https://mi-app.dev.jgcloud.es
```

## Comandos Útiles

### Actualizar Aplicación
```bash
# Reconstruir imagen
sudo docker build -t mi-app:latest .
sudo docker save mi-app:latest | sudo k3s ctr images import -

# Reiniciar deployment para usar nueva imagen
kubectl rollout restart deployment/mi-app -n mi-app
```

### Ver Logs en Tiempo Real
```bash
kubectl logs -f deployment/mi-app -n mi-app
```

### Escalar Aplicación
```bash
kubectl scale deployment/mi-app --replicas=3 -n mi-app
```

### Eliminar Aplicación
```bash
kubectl delete -k k8s/
# o
kubectl delete namespace mi-app
```

## Checklist de Despliegue

- [ ] Crear Dockerfile de producción
- [ ] Crear directorio `k8s/` con manifiestos
- [ ] Configurar variables de entorno en ConfigMap
- [ ] Configurar secrets (credenciales, API keys)
- [ ] Construir imagen Docker
- [ ] Importar imagen a k3s
- [ ] Aplicar manifiestos con `kubectl apply -k k8s/`
- [ ] Verificar pod running
- [ ] Verificar certificado TLS ready
- [ ] Test endpoint HTTPS

## Notas Importantes

1. **Wildcard DNS**: `*.dev.jgcloud.es` apunta al servidor, cualquier subdominio funciona automáticamente.

2. **Certificados TLS**: cert-manager genera certificados Let's Encrypt automáticamente al crear el Ingress con la anotación `cert-manager.io/cluster-issuer: letsencrypt-prod`.

3. **Imágenes Locales**: Al usar `imagePullPolicy: IfNotPresent`, k3s usa la imagen local importada.

4. **Recursos**: Ajustar `resources.requests` y `resources.limits` según las necesidades de la aplicación.

5. **Health Checks**: Configurar `livenessProbe` y `readinessProbe` apropiadamente para la aplicación.
