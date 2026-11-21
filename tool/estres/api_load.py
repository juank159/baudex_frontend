# Carga a los endpoints que usan las pantallas (factura, productos, clientes,
# kardex, saldos, movimientos, órdenes de compra, notas crédito, tablero, sync).
# Cada endpoint: N peticiones con C a la vez; da p50/p95/peor y tamaño.
# Uso: QA_URL=http://127.0.0.1:3101/api python3 tool/estres/api_load.py [C=8] [N=40] > carga.md
import sys, random, json, time, concurrent.futures as cf
sys.path.insert(0, __import__("os").path.dirname(__file__))
from qa_api import req, unwrap, login, pct
from urllib.parse import quote
C = int(sys.argv[1]) if len(sys.argv) > 1 else 8
N = int(sys.argv[2]) if len(sys.argv) > 2 else 40
tok = login("qa-load")
def first_list(path):
    d = unwrap(req("GET", path, None, tok)[1])
    if isinstance(d, dict):
        for k in ("data", "items", "results"):
            if isinstance(d.get(k), list): return d[k]
    return d if isinstance(d, list) else []
prods = first_list("/products?limit=100&page=1")
custs = first_list("/customers?limit=100&page=1")
invs = first_list("/invoices?limit=100&page=1")
pos = first_list("/purchase-orders?limit=100&page=1")
cns = first_list("/credit-notes?limit=100&page=1")
hot = [p["id"] for p in prods[:5]] or [None]
# Producto con más movimientos (kardex más largo)
code, d, _, _ = req("GET", "/inventory/movements?limit=1&page=1", None, tok)
today = time.strftime("%Y-%m-%d")
eps = {
    "GET /products (lista 50)": lambda i: f"/products?limit=50&page={1 + i % 20}",
    "GET /products?search=": lambda i: f"/products?search={quote(random.choice(['arroz','marca1','queso','77','leche marca2']))}&limit=20",
    "GET /products/search": lambda i: f"/products/search?term={random.choice(['arroz','marca1','queso'])}&limit=20",
    "GET /products/barcode/:code": lambda i: f"/products/barcode/{random.choice(prods)['barcode']}" if prods and prods[0].get('barcode') else "/products?limit=1",
    "GET /products/:id": lambda i: f"/products/{random.choice(prods)['id']}",
    "GET /customers (lista 50)": lambda i: f"/customers?limit=50&page={1 + i % 10}",
    "GET /customers/search": lambda i: f"/customers/search?term={quote(random.choice(['genesis','apellido 1','3000']))}&limit=20",
    "GET /invoices (lista 50)": lambda i: f"/invoices?limit=50&page={1 + i % 20}",
    "GET /invoices?search=": lambda i: f"/invoices?search={random.choice(['FAC','genesis','10'])}&limit=20",
    "GET /invoices/:id": lambda i: f"/invoices/{random.choice(invs)['id']}",
    "GET /invoices/stats": lambda i: "/invoices/stats",
    "GET kardex producto vendido": lambda i: f"/inventory/products/{random.choice(hot)}/kardex",
    "GET /inventory/balances": lambda i: f"/inventory/balances?limit=50&page={1 + i % 10}",
    "GET /inventory/movements": lambda i: f"/inventory/movements?limit=50&page={1 + i % 10}",
    "GET /inventory/stats": lambda i: "/inventory/stats",
    "GET /inventory/summary": lambda i: "/inventory/summary",
    "GET /purchase-orders": lambda i: f"/purchase-orders?limit=50&page={1 + i % 5}",
    "GET /purchase-orders/:id": lambda i: f"/purchase-orders/{random.choice(pos)['id']}" if pos else "/purchase-orders?limit=1",
    "GET /credit-notes": lambda i: f"/credit-notes?limit=50&page={1 + i % 5}",
    "GET /credit-notes/:id": lambda i: f"/credit-notes/{random.choice(cns)['id']}" if cns else "/credit-notes?limit=1",
    "GET /dashboard/summary hoy": lambda i: f"/dashboard/summary?startDate={today}&endDate={today}",
    "GET /dashboard/summary mes": lambda i: f"/dashboard/summary?startDate={today[:8]}01&endDate={today}",
    "GET /sync/changes/products (desde 0)": lambda i: "/sync/changes/products?since=1970-01-01T00:00:00.000Z&limit=500",
    "GET /sync/changes/invoices (desde 0)": lambda i: "/sync/changes/invoices?since=1970-01-01T00:00:00.000Z&limit=500",
    "GET /sync/changes/inventory_movements": lambda i: "/sync/changes/inventory_movements?since=1970-01-01T00:00:00.000Z&limit=500",
}
only = __import__("os").environ.get("QA_ONLY")
print(f"Carga: {C} a la vez, {N} peticiones por endpoint · {time.strftime('%H:%M')}\n")
print("| endpoint | código | p50 ms | p95 ms | peor ms | KB resp |")
print("|---|---|---|---|---|---|")
for name, f in eps.items():
    if only and only not in name: continue
    def one(i):
        c, d, ms, n = req("GET", f(i), None, tok, timeout=180)
        return c, ms, n, (d if c >= 400 else None)
    # El tablero carga TODAS las facturas del período en memoria (≈500 MB por
    # petición con 20 mil facturas): con 8 a la vez el servidor muere por
    # memoria. Se mide con 2 a la vez para no tumbarlo (QA_DASH_C para forzar).
    c_, n_ = (int(__import__("os").environ.get("QA_DASH_C", 2)), 6) if "dashboard" in name else (C, N)
    with cf.ThreadPoolExecutor(c_) as ex: rs = list(ex.map(one, range(n_)))
    ms = [r[1] for r in rs]; codes = sorted({r[0] for r in rs})
    err = next((r[3] for r in rs if r[3]), None)
    print(f"| {name} | {','.join(map(str, codes))} | {pct(ms,.5):.0f} | {pct(ms,.95):.0f} | {max(ms):.0f} | {sum(r[2] for r in rs)/len(rs)/1024:.0f} |" + (f" {str(err)[:120]}" if err else ""), flush=True)
