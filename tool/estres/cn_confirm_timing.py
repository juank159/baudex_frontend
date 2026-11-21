# Tiempo de confirmar notas crédito en borrador por la API (lo que espera la
# app tras "Confirmar"). Crea N borradores sobre facturas recientes y confirma.
# Además prueba confirmar DOS veces la misma (lo que pasa si la app reintenta
# por tiempo agotado). Uso: python3 tool/estres/cn_confirm_timing.py [N=10]
import sys, os, time, concurrent.futures as cf
sys.path.insert(0, os.path.dirname(__file__))
from qa_api import req, unwrap, login, pct
N = int(sys.argv[1]) if len(sys.argv) > 1 else 10
tok = login("qa-cn")
d = unwrap(req("GET", "/invoices?limit=100&page=3", None, tok)[1])
invs = d["data"] if isinstance(d, dict) else d
made, create_ms, conf_ms, second = [], [], [], []
for inv in invs:
    if len(made) >= N: break
    full = unwrap(req("GET", f"/invoices/{inv['id']}", None, tok)[1])
    items = full.get("items") or []
    if not items: continue
    it = items[0]
    c, cn, ms, _ = req("POST", "/credit-notes", {"invoiceId": inv["id"], "type": "partial", "reason": "returned_goods", "restoreInventory": True,
        "items": [{"invoiceItemId": it["id"], "productId": it.get("productId"), "description": it["description"], "quantity": 1, "unitPrice": float(it["unitPrice"])}]}, tok)
    if c not in (200, 201): continue
    create_ms.append(ms); made.append(unwrap(cn)["id"])
for cid in made:
    c, r, ms, _ = req("POST", f"/credit-notes/{cid}/confirm", {}, tok)
    conf_ms.append(ms)
    c2, r2, ms2, _ = req("POST", f"/credit-notes/{cid}/confirm", {}, tok)
    second.append((c2, str(unwrap(r2))[:120]))
# Confirmación simultánea de la misma nota (doble clic / reintento a la vez)
dup = None
if invs:
    inv = invs[-1]; full = unwrap(req("GET", f"/invoices/{inv['id']}", None, tok)[1]); it = full["items"][0]
    c, cn, _, _ = req("POST", "/credit-notes", {"invoiceId": inv["id"], "type": "partial", "reason": "returned_goods", "restoreInventory": True,
        "items": [{"invoiceItemId": it["id"], "productId": it.get("productId"), "description": it["description"], "quantity": 1, "unitPrice": float(it["unitPrice"])}]}, tok)
    if c in (200, 201):
        cid = unwrap(cn)["id"]
        with cf.ThreadPoolExecutor(2) as ex: dup = list(ex.map(lambda _: req("POST", f"/credit-notes/{cid}/confirm", {}, tok)[:1] + (0,), range(2)))
        dup = [x[0] for x in dup]
        # Verificar con el DATO, no con la respuesta
        import shlex, subprocess
        PSQL = shlex.split(os.environ.get("QA_PSQL", "docker exec -i ecommerce psql -U baudex_qa -d baudex_qa"))
        def sql(q): return subprocess.run(PSQL + ["-XAtc", q], capture_output=True, text=True).stdout.strip()
        movs = sql(f"select count(*) from inventory_movements where \"referenceId\"='{cid}'")
        cred = sql(f"select i.credited_amount || ' / nota ' || c.total from credit_notes c join invoices i on i.id=c.invoice_id where c.id='{cid}'")
        print(f"   movimientos de devolución de esa nota: {movs} (debe ser {len(full['items'][:1])})")
        print(f"   factura acreditada / total nota: {cred} (si se acreditó antes otra nota, súmela)")
print(f"notas creadas {len(made)} · crear p50 {pct(create_ms,.5):.0f} ms p95 {pct(create_ms,.95):.0f}")
print(f"confirmar p50 {pct(conf_ms,.5):.0f} ms · p95 {pct(conf_ms,.95):.0f} · peor {max(conf_ms or [0]):.0f}")
print("segunda confirmación de la misma nota:", sorted({s[0] for s in second}), second[0][1] if second else "")
print("dos confirmaciones simultáneas:", dup)
print("ids:", ",".join(made))
