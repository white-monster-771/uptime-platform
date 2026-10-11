#!/bin/bash
set -e
# Копия базы Kuma в ~/backups, хранить 5 последних.
BACKUP_DIR="$HOME/backups"
mkdir -p "$BACKUP_DIR"
POD=$(kubectl -n uptime get pod -l app=kuma -o jsonpath='{.items[0].metadata.name}')
STAMP=$(date +%F_%H%M%S)
kubectl -n uptime cp "$POD":/app/data/kuma.db "$BACKUP_DIR/kuma-$STAMP.db"
ls -1t "$BACKUP_DIR"/kuma-*.db 2>/dev/null | tail -n +6 | xargs -r rm -f
echo "Backup: $BACKUP_DIR/kuma-$STAMP.db"
