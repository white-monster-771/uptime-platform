#!/bin/bash
# Развернуть платформу с нуля: зависимости -> кластер k3d -> манифесты.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

command -v docker >/dev/null 2>&1 || curl -fsSL https://get.docker.com | sh
command -v helm   >/dev/null 2>&1 || curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
command -v k3d    >/dev/null 2>&1 || curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

if ! command -v kubectl >/dev/null 2>&1; then
  tmp="$(mktemp -d)"
  curl -fsSL "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o "$tmp/kubectl"
  install "$tmp/kubectl" /usr/local/bin/kubectl
  rm -rf "$tmp"
fi

if ! k3d cluster list 2>/dev/null | grep -q '^uptime'; then
  k3d cluster create uptime \
    --servers 1 --agents 0 \
    --port "80:80@loadbalancer" \
    --port "443:443@loadbalancer" \
    --k3s-arg "--disable=traefik@server:0"
fi

k3d kubeconfig merge uptime --kubeconfig-switch-context >/dev/null

cd "$REPO_ROOT"
bash scripts/deploy.sh

IP="$(hostname -I | awk '{print $1}')"
echo "Platform URL: http://$IP/"
echo "Prometheus:   http://$IP/prometheus"
echo "Demo:         http://$IP/demo"
