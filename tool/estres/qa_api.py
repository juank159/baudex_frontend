# Utilidades comunes para los guiones de estrés contra el servidor de PRUEBAS.
import json, os, time, urllib.request, urllib.error
B = os.environ.get("QA_URL", "http://127.0.0.1:3101/api")
assert "127.0.0.1" in B or "localhost" in B, "solo contra un servidor local de pruebas"
EMAIL, PWD = os.environ.get("QA_EMAIL", "qa@baudex.test"), os.environ.get("QA_PASSWORD", "Prueba123!")
def req(method, path, body=None, tok=None, dev="qa-load", timeout=120):
    h = {"Content-Type": "application/json", "X-Device-Id": dev, "User-Agent": "Baudex (Desktop; macOS 14)"}
    if tok: h["Authorization"] = "Bearer " + tok
    r = urllib.request.Request(B + path, method=method, data=json.dumps(body).encode() if body is not None else None, headers=h)
    t = time.perf_counter()
    try:
        with urllib.request.urlopen(r, timeout=timeout) as resp:
            raw = resp.read(); code = resp.status
    except urllib.error.HTTPError as e:
        raw = e.read(); code = e.code
    except Exception as e:
        return 0, str(e), (time.perf_counter() - t) * 1000, 0
    ms = (time.perf_counter() - t) * 1000
    try: data = json.loads(raw) if raw else None
    except Exception: data = raw.decode(errors="replace")[:300]
    return code, data, ms, len(raw)
def unwrap(d):
    while isinstance(d, dict) and "data" in d and set(d) <= {"success", "data", "timestamp", "message", "meta"}: d = d["data"]
    return d
def login(dev="qa-load"):
    code, d, _, _ = req("POST", "/auth/login", {"email": EMAIL, "password": PWD}, dev=dev)
    assert code in (200, 201), (code, d)
    return unwrap(d)["token"]
def pct(l, q):
    s = sorted(l); return s[min(len(s) - 1, int(round((len(s) - 1) * q)))] if s else 0
