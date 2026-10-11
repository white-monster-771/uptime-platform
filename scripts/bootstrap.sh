#!/bin/bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$REPO_ROOT/../.env"
[ -f "$ENV_FILE" ] && set -a && . "$ENV_FILE" && set +a
PORT_HTTP="${PORT_HTTP:-80}"

command -v docker >/dev/null 2>&1 || curl -fsSL https://get.docker.com | sh
command -v helm   >/dev/null 2>&1 || curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
command -v k3d    >/dev/null 2>&1 || curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
if ! command -v kubectl >/dev/null 2>&1; then
  tmp="$(mktemp -d)"
  curl -fsSL "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o "$tmp/kubectl"
  install "$tmp/kubectl" /usr/local/bin/kubectl; rm -rf "$tmp"
fi

if ! k3d cluster list 2>/dev/null | grep -q '^uptime'; then
  if ss -ltn | grep -qE ":${PORT_HTTP}\b"; then
    echo "Port ${PORT_HTTP} busy on host. Set PORT_HTTP in .env or free it. Aborting." >&2
    exit 1
  fi
  k3d cluster create uptime --servers 1 --agents 0 \
    --port "${PORT_HTTP}:80@loadbalancer" --port "443:443@loadbalancer" \
    --k3s-arg "--disable=traefik@server:0"
fi
k3d kubeconfig merge uptime --kubeconfig-switch-context >/dev/null

cd "$REPO_ROOT"
bash scripts/deploy.sh
echo "Platform:  http://${HOST_IP:-$(hostname -I | awk '{print $1}')}:${PORT_HTTP}/"
echo "Prometheus: http://${HOST_IP:-$(hostname -I | awk '{print $1}')}:${PORT_HTTP}/prometheus"
echo "Demo:       http://${HOST_IP:-$(hostname -I | awk '{print $1}')}:${PORT_HTTP}/demo"
