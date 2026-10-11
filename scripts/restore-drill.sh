#!/bin/bash
set -e
NS=restore-test
SRC=$(ls -1t "$HOME"/backups/kuma-*.db | head -1)
echo "From: $SRC"

kubectl apply -f - <<NS
apiVersion: v1
kind: Namespace
metadata: { name: $NS }
NS

kubectl apply -f - <<PVC
apiVersion: v1
kind: PersistentVolumeClaim
metadata: { name: kuma-restore-data, namespace: $NS }
spec:
  accessModes: [ReadWriteOnce]
  resources: { requests: { storage: 1Gi } }
PVC

kubectl -n "$NS" delete pod loader --ignore-not-found=true
kubectl -n "$NS" run loader --image=alpine:3.20 --restart=Never \
  --overrides='{"spec":{"containers":[{"name":"loader","image":"alpine:3.20","command":["sleep","3600"],"volumeMounts":[{"name":"d","mountPath":"/data"}]}],"volumes":[{"name":"d","persistentVolumeClaim":{"claimName":"kuma-restore-data"}}]}}'
kubectl -n "$NS" wait --for=condition=ready pod/loader --timeout=120s
kubectl -n "$NS" cp "$SRC" loader:/data/kuma.db
kubectl -n "$NS" delete pod loader --wait=true

kubectl apply -f - <<DEP
apiVersion: apps/v1
kind: Deployment
metadata: { name: kuma-restore, namespace: $NS }
spec:
  replicas: 1
  selector:
    matchLabels: { app: kuma-restore }
  template:
    metadata:
      labels: { app: kuma-restore }
    spec:
      containers:
      - name: kuma-restore
        image: louislam/uptime-kuma:1
        ports:
        - containerPort: 3001
        volumeMounts:
        - name: d
          mountPath: /app/data
      volumes:
      - name: d
        persistentVolumeClaim: { claimName: kuma-restore-data }
DEP

kubectl apply -f - <<SVC
apiVersion: v1
kind: Service
metadata: { name: kuma-restore-svc, namespace: $NS }
spec:
  selector: { app: kuma-restore }
  ports:
  - protocol: TCP
    port: 3001
    targetPort: 3001
SVC

kubectl -n "$NS" wait --for=condition=ready pod -l app=kuma-restore --timeout=180s
echo "Verify: kubectl -n $NS port-forward svc/kuma-restore-svc 3001:3001"
echo "Then http://localhost:3001 ; cleanup: ./scripts/restore-cleanup.sh"
