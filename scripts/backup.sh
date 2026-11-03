#!/bin/bash
set -e
BACKUP_DIR="$HOME/backups"
mkdir -p "$BACKUP_DIR"
POD=$(kubectl -n uptime get pod -l app=kuma -o jsonpath='{.items[0].metadata.name}')
STAMP=$(date +%F_%H%M%S)
DEST="$BACKUP_DIR/kuma-$STAMP"
mkdir -p "$DEST"
for f in kuma.db kuma.db-wal kuma.db-shm; do
  kubectl -n uptime cp "$POD":/app/data/$f "$DEST/$f" 2>/dev/null || true
done
ls -1dt "$BACKUP_DIR"/kuma-*/ 2>/dev/null | tail -n +6 | xargs -r rm -rf
echo "Backup dir: $DEST"
ls -lh "$DEST"
