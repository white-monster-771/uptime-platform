#!/bin/bash
# Проверить, что все поды платформы живы (после перезагрузки ВМ).
set -euo pipefail

kubectl get nodes >/dev/null 2>&1 || { echo "cluster unreachable"; exit 1; }

not_ready="$(kubectl get pods -A --no-headers 2>/dev/null | grep -vE 'Running|Completed' || true)"
if [ -z "$not_ready" ]; then
  echo "all pods healthy"
  echo "URL: http://$(hostname -I | awk '{print $1}')/"
else
  echo "$not_ready"
  exit 1
fi
python3 "$(dirname "$0")/check_health.py"
