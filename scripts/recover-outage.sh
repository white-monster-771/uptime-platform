#!/bin/bash
echo "Восстанавливаю demo backend (replicas=1)..."
kubectl -n demo scale deployment whoami --replicas=1
echo "Жди ~30 сек, Kuma должен вернуться в UP."
