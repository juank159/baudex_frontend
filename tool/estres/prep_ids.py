# Prepara datos frescos para una corrida de la app: notas crédito en BORRADOR
# de distintos tipos y órdenes de compra en borrador. Escribe los ids en
# <salida>/cn_ids y <salida>/po_ids. Uso: python3 tool/estres/prep_ids.py <salida> [n=8]
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from qa_api import req, unwrap, login
out = sys.argv[1]; n = int(sys.argv[2]) if len(sys.argv) > 2 else 8
tok = login("qa-prep")
def lst(path):
    d = unwrap(req("GET", path, None, tok)[1]); return d.get("data", d) if isinstance(d, dict) else d
made = []
kinds = [("partial", True, "paid"), ("full", True, "paid"), ("partial", False, "paid"), ("partial", True, "pending")]
page = 5
while len(made) < n and page < 40:
    for inv in lst(f"/invoices?limit=50&page={page}"):
        if len(made) >= n: break
        kind = kinds[len(made) % len(kinds)]
        if inv.get("status") != kind[2]: continue
        full = unwrap(req("GET", f"/invoices/{inv['id']}", None, tok)[1])
        items = full.get("items") or []
        if not items: continue
        use = items if kind[0] == "full" else items[:1]
        body = {"invoiceId": inv["id"], "type": kind[0], "reason": "returned_goods", "restoreInventory": kind[1],
                "items": [{"invoiceItemId": it["id"], "productId": it.get("productId"), "description": it["description"],
                           "quantity": float(it["quantity"]) if kind[0] == "full" else 1, "unitPrice": float(it["unitPrice"])} for it in use]}
        c, d, _, _ = req("POST", "/credit-notes", body, tok)
        if c in (200, 201): made.append(unwrap(d)["id"]); print("nota", kind, unwrap(d)["number"])
        else: print("no se pudo", kind, str(d)[:150])
    page += 1
pos = [p["id"] for p in lst("/purchase-orders?limit=50&page=1&status=draft") if p.get("status") == "draft"][:6]
open(os.path.join(out, "cn_ids"), "w").write(",".join(made))
open(os.path.join(out, "po_ids"), "w").write(",".join(pos))
print(len(made), "notas,", len(pos), "órdenes")
