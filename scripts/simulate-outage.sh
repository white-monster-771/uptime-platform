#!/bin/bash
echo "Гашу demo backend (replicas=0)..."
kubectl -n demo scale deployment whoami --replicas=0
echo "Жди ~30-60 сек, Kuma должен показать DOWN."
