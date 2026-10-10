# Uptime Platform

Self-hosted мониторинг доступности сервисов на Kubernetes.
Ядро — Uptime Kuma, доступ через Traefik Ingress, данные на PVC.
Demo-backend (whoami) для демонстрации детектирования отказа.

## Запуск
./scripts/deploy.sh

## Демонстрация отказа
1. Монитор Demo Backend в Kuma = UP.
2. ./scripts/simulate-outage.sh  -> Kuma DOWN, /demo отдаёт 503.
3. ./scripts/recover-outage.sh   -> Kuma снова UP.
