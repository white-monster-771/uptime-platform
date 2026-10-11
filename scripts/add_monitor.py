#!/usr/bin/env python3
# Add an HTTP monitor to Uptime Kuma via its REST API. stdlib only.
import json, os, sys, time, urllib.request, urllib.error

def load_env(path):
    cfg = {}
    if os.path.exists(path):
        for line in open(path):
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1); cfg[k.strip()] = v.strip()
    return cfg

env = load_env(os.path.join(os.path.dirname(__file__), "..", ".env"))
base = env.get("KUMA_BASE_URL", "").rstrip("/")
token = env.get("KUMA_API_TOKEN", "")
if not base or not token:
    sys.exit("Set KUMA_BASE_URL and KUMA_API_TOKEN in .env"); 
if len(sys.argv) < 3:
    sys.exit("usage: add_monitor.py <name> <url> [interval_sec]")

name, url = sys.argv[1], sys.argv[2]
interval = int(sys.argv[3]) if len(sys.argv) > 3 else 60

def req(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(base + path, data=data, method=method,
        headers={"Authorization": "Bearer " + token,
                 "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(r, timeout=15) as resp:
            raw = resp.read().decode()
            try: return resp.status, json.loads(raw)
            except Exception: return resp.status, raw
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()
    except Exception as e:
        return None, str(e)

st, lst = req("GET", "/api/monitors")
if st != 200:
    sys.exit(f"auth/list failed status={st} body={lst}")
print(f"existing monitors: {len(lst) if isinstance(lst, list) else '?'}")

payload = {"type": "http", "name": name, "url": url, "method": "GET",
           "interval": interval, "timeout": 30, "retryInterval": 30,
           "active": True}
for attempt in range(3):
    st, out = req("POST", "/api/monitors", payload)
    if st in (200, 201):
        mid = out.get("id") if isinstance(out, dict) else out
        print(f"created monitor id={mid} name={name}"); sys.exit(0)
    if st and st >= 500:
        time.sleep(2 * (attempt + 1)); continue
    sys.exit(f"create failed status={st} raw={out}")
sys.exit("create failed after retries")
