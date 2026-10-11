#!/bin/bash
# Снести песочницу восстановления.
kubectl delete namespace restore-test --ignore-not-found=true
echo "Sandbox removed."
