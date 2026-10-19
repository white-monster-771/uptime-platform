# Uptime Platform

Reproducible Kubernetes monitoring stand. Built as a portfolio piece, not a
turnkey product: the goal is that a stranger can `clone -> bootstrap -> verify`
and see a live availability monitor with proven outage detection and a tested
backup/restore path.

## Stack
- k3d (single-server cluster), Debian/Ubuntu host
- Uptime Kuma (availability UI) + PVC for the SQLite DB
- Traefik (Ingress Controller, metrics exposed)
- Prometheus (scrapes Traefik; Kuma metrics limited by upstream auth - see Notes)
- whoami demo backend for failure simulation
- Bash + one Python tool (`scripts/check_health.py`, stdlib only)

## What it looks like

Healthy state — Uptime Kuma tracking the demo backend:

![Kuma UP](docs/screenshots/01-kuma-up.png)

Outage detected — same dashboard after `simulate-outage.sh`, monitor flips to Down:

![Kuma DOWN](docs/screenshots/02-kuma-down.png)

Machine-readable health — `check_health.py` reads Prometheus JSON and encodes the
verdict as a process exit code (something shell cannot do cleanly):

![Health check](docs/screenshots/03-health-check.png)

## Quickstart (clean VM)

    git clone <repo> && cd uptime-platform
    cp .env.example .env      # set HOST_IP, PORT_HTTP
    ./scripts/bootstrap.sh    # deps -> cluster -> manifests
    ./scripts/verify.sh       # all pods healthy?

## Operate
- Health of the observability layer: `python3 scripts/check_health.py`
- Simulate outage / recover: `scripts/simulate-outage.sh` / `recover-outage.sh`
- Backup DB / restore-drill / cleanup: `scripts/backup.sh` / `restore-drill.sh` / `restore-cleanup.sh`

## Boundaries (known, deliberate)
- Targets a CLEAN host: bootstrap hard-binds PORT_HTTP/443 and aborts if busy
  rather than overwriting an existing ingress.
- Uptime Kuma does NOT auto-discover cluster services; monitors are added via
  UI. Auto-discovery would be a different architecture (Prometheus Operator +
  Blackbox Exporter), intentionally out of scope.
- Management is scripts + `.env`, not a web admin panel.
- Kuma `/metrics` has no HTTP API in this build (socket.io only); Prometheus
  scrapes Traefik instead. Kuma metrics are a roadmap item, not a defect.

## Roadmap (not debt)
- Integration tests (pytest) for the outage scenario
- Helm chart packaging with values.yaml
- TLS via cert-manager
