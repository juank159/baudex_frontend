# ¿Las respuestas traen contraseñas o códigos? Revisa recursivamente las claves
# de login, perfil, facturas, notas crédito, órdenes y usuarios.
# Uso: QA_URL=... python3 tool/estres/secret_leak_check.py
import sys, os, re
sys.path.insert(0, os.path.dirname(__file__))
from qa_api import req, unwrap, EMAIL, PWD
BAD = re.compile(r"(password|passwd|hash|verification_?code|verificationcode|reset_?(password_)?(token|code)|resetcode|otp|secret|api_?key)", re.I)
def walk(o, path, hits):
    if isinstance(o, dict):
        for k, v in o.items():
            p = f"{path}.{k}"
            if BAD.search(k) and v not in (None, "", [], {}): hits.add(re.sub(r"\[\d+\]", "[]", p))
            walk(v, p, hits)
    elif isinstance(o, list):
        for i, v in enumerate(o[:20]): walk(v, f"{path}[{i}]", hits)
c, d, _, _ = req("POST", "/auth/login", {"email": EMAIL, "password": PWD}, dev="qa-sec")
tok = unwrap(d)["token"]
checks = {"POST /auth/login": d}
def lst(path):
    x = unwrap(req("GET", path, None, tok, "qa-sec")[1]); return x
inv = lst("/invoices?limit=5&page=1"); checks["GET /invoices"] = inv
ids = (inv.get("data") if isinstance(inv, dict) else inv) or []
if ids: checks["GET /invoices/:id"] = lst(f"/invoices/{ids[0]['id']}")
for p in ["/auth/profile", "/credit-notes?limit=5", "/purchase-orders?limit=5", "/users", "/customers?limit=5", "/organizations/current", "/cash-register/current"]:
    checks["GET " + p] = lst(p)
cn = lst("/credit-notes?limit=1"); cl = (cn.get("data") if isinstance(cn, dict) else cn) or []
if cl: checks["GET /credit-notes/:id"] = lst(f"/credit-notes/{cl[0]['id']}")
# Confirmar una nota con Idempotency-Key (como la app): la respuesta guardada en
# idempotency_keys tampoco debe tener contraseñas ni códigos.
import json, uuid, urllib.request, shlex, subprocess
from qa_api import B
for x in (cl or []):
    pass
inv_l = (inv.get("data") if isinstance(inv, dict) else inv) or []
full = lst(f"/invoices/{inv_l[-1]['id']}") if inv_l else None
if full and full.get("items"):
    it = full["items"][0]
    c, cnd, _, _ = req("POST", "/credit-notes", {"invoiceId": full["id"], "type": "partial", "reason": "returned_goods", "restoreInventory": False,
        "items": [{"invoiceItemId": it["id"], "description": it["description"], "quantity": 1, "unitPrice": float(it["unitPrice"])}]}, tok, "qa-sec")
    if c in (200, 201):
        cid = unwrap(cnd)["id"]; key = str(uuid.uuid4())
        r = urllib.request.Request(B + f"/credit-notes/{cid}/confirm", method="POST", data=b"{}", headers={"Content-Type": "application/json",
            "Authorization": "Bearer " + tok, "X-Device-Id": "qa-sec", "Idempotency-Key": key})
        body = json.loads(urllib.request.urlopen(r, timeout=60).read())
        checks["POST /credit-notes/:id/confirm (con Idempotency-Key)"] = body
        PSQL = shlex.split(os.environ.get("QA_PSQL", "docker exec -i ecommerce psql -U baudex_qa -d baudex_qa"))
        stored = subprocess.run(PSQL + ["-XAtc", f"select response from idempotency_keys where path like '%{cid}%' order by created_at desc limit 1"], capture_output=True, text=True).stdout.strip()
        try: checks["idempotency_keys.response guardada"] = json.loads(stored) if stored else {}
        except Exception: checks["idempotency_keys.response guardada"] = {"_texto": stored[:2000], "password": "?" if '"password"' in stored else None}
bad = 0
for name, body in checks.items():
    hits = set(); walk(body, "", hits)
    print(f"{'FALLA' if hits else 'ok   '} {name}" + (f"  → {sorted(hits)[:6]}" if hits else ""))
    bad += bool(hits)
print("endpoints con contraseñas/códigos:", bad)
