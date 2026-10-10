#!/bin/bash
set -e

if ! command -v kubectl &> /dev/null; then
  echo "Ошибка: kubectl не найден."; exit 1
fi

echo "=== Traefik (Ingress Controller) ==="
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
helm upgrade --install traefik traefik/traefik \
  --namespace traefik --create-namespace \
  --set service.type=ClusterIP \
  --set ports.web.port=80 \
  --set ports.web.targetPort=80 \
  --set providers.kubernetesIngress.enabled=true

echo "=== Uptime Kuma ==="
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/pvc.yaml
kubectl apply -f manifests/deployment.yaml
kubectl apply -f manifests/service.yaml
kubectl apply -f manifests/ingress.yaml

echo "=== Demo backend (whoami) ==="
kubectl apply -f manifests/demo-namespace.yaml
kubectl apply -f manifests/demo-deployment.yaml
kubectl apply -f manifests/demo-service.yaml
kubectl apply -f manifests/demo-ingress.yaml

echo "Ждём готовности подов"
kubectl -n uptime wait --for=condition=ready pod -l app=kuma --timeout=180s
kubectl -n demo   wait --for=condition=ready pod -l app=whoami --timeout=180s

echo "Деплой завершён"
