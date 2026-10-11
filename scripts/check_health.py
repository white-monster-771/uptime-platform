#!/usr/bin/env python3
# Machine check: is the observability layer healthy? Exit 1 if not.
import json, os, sys, urllib.request, urllib.error

def load_env(p):
    c = {}
    if os.path.exists(p):
        for ln in open(p):
            ln = ln.strip()
            if ln and not ln.startswith("#") and "=" in ln:
                k, v = ln.split("=", 1); c[k.strip()] = v.strip()
    return c

env = load_env(os.path.join(os.path.dirname(__file__), "..", ".env"))
host = env.get("HOST_IP", "")
if not host:
    sys.exit("HOST_IP missing in .env")
url = f"http://{host}/prometheus/api/v1/targets"

try:
    with urllib.request.urlopen(url, timeout=15) as r:
        raw = r.read().decode()
        doc = json.loads(raw)
except urllib.error.HTTPError as e:
    sys.exit(f"prometheus HTTP {e.code}: {e.read().decode()[:200]}")
except Exception as e:
    sys.exit(f"prometheus unreachable: {e}")

if doc.get("status") != "success" or "activeTargets" not in doc.get("data", {}):
    sys.exit(f"unexpected shape, raw[:300]={raw[:300]}")

targets = doc["data"]["activeTargets"]
up = [t for t in targets if t.get("health") == "up"]
down = [t for t in targets if t.get("health") != "up"]
print(f"targets total={len(targets)} up={len(up)} down={len(down)}")
for t in down:
    lbl = t.get("labels", {})
    print(f"  DOWN job={lbl.get('job')} inst={lbl.get('instance')} err={t.get('lastError') or '(none)'}")
if down:
    sys.exit(1)
print("observability healthy")
