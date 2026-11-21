# Siembra volumen realista en la base de PRUEBAS baudex_qa a través de la API
# (así se crean también kardex, lotes FIFO y saldos como lo haría la app).
# Uso: QA_URL=http://127.0.0.1:3101/api python3 tool/estres/seed_qa.py [productos] [clientes] [facturas]
import json, os, random, sys, time, urllib.request, urllib.error, concurrent.futures as cf
B = os.environ.get("QA_URL", "http://127.0.0.1:3101/api")
assert ":3101" in B or os.environ.get("QA_ALLOW_URL"), "solo contra el servidor de pruebas"
OUT = os.environ.get("QA_OUT", os.path.dirname(os.path.abspath(__file__)) + "/.qa_ids.json")
EMAIL, PWD = os.environ.get("QA_EMAIL", "qa@baudex.test"), os.environ.get("QA_PASSWORD", "Prueba123!")
NP, NC, NI = (int(a) for a in (sys.argv[1:4] + ["5000", "2000", "20000"][len(sys.argv[1:4]):]))
random.seed(7)
RUN = int(os.environ.get("QA_RUN", int(time.time()) % 90 + 10))  # prefijo para no chocar con siembras anteriores

def req(method, path, body=None, tok=None):
    h = {"Content-Type": "application/json", "X-Device-Id": os.environ.get("QA_DEV", "qa-seed"), "User-Agent": "Baudex (Desktop; macOS 14)"}
    if tok: h["Authorization"] = "Bearer " + tok
    r = urllib.request.Request(B + path, method=method, data=json.dumps(body).encode() if body is not None else None, headers=h)
    try:
        with urllib.request.urlopen(r, timeout=120) as resp: return resp.status, json.loads(resp.read() or b"null")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:300]
def unwrap(d):
    while isinstance(d, dict) and "data" in d and set(d) <= {"success", "data", "timestamp", "message", "meta"}: d = d["data"]
    return d
def ok(r): return r[0] in (200, 201)
# Nota: el servidor permite UNA sesión por equipo (X-Device-Id). Si otro guion
# inicia sesión con el mismo equipo, esta sesión muere: usar QA_DEV distinto.

code, d = req("POST", "/auth/login", {"email": EMAIL, "password": PWD})
tok = unwrap(d)["token"]
cat = unwrap(req("POST", "/categories", {"name": "General QA %d" % time.time(), "slug": "general-qa-%d" % time.time()}, tok)[1])
cid = cat["id"]
req("POST", "/cash-register/open", {"openingAmount": 100000}, tok)
words = ["Arroz", "Aceite", "Azucar", "Leche", "Huevo", "Pan", "Galleta", "Chicle", "Caramelo", "Gaseosa", "Jabon",
         "Papel", "Cafe", "Sal", "Harina", "Atun", "Pasta", "Frijol", "Lenteja", "Queso", "Mantequilla", "Detergente"]
def prod(i):
    price = random.choice([500, 1000, 1500, 2500, 3200, 4500, 8000, 12000, 25000])
    r = req("POST", "/products", {"name": f"{random.choice(words)} Marca{i % 41} R{RUN} {i}", "sku": f"QA{RUN}-{i:05d}",
        "barcode": f"77{RUN:02d}{i:09d}", "categoryId": cid, "stock": 100000,
        "prices": [{"type": "price1", "name": "Público", "amount": price}, {"type": "cost", "name": "Costo", "amount": int(price * .7)}]}, tok)
    if not ok(r) and i < 3: print("producto falló", r, flush=True)
    return unwrap(r[1]) if ok(r) else None
first = ["Genesis", "Fany", "Keyla", "Hugo", "Yolimar", "Darcy", "Mayuri", "Sol", "Kany", "Anthony", "Carmen", "Isis", "Nelly", "José", "Javier"]
def cust(i):
    r = req("POST", "/customers", {"firstName": random.choice(first), "lastName": f"Apellido {i}", "documentType": "cc",
        "documentNumber": f"{RUN}{i:07d}", "email": f"c{RUN}-{i}@qa.test", "creditLimit": 50000000}, tok)
    return unwrap(r[1]) if ok(r) else None
t = time.time()
with cf.ThreadPoolExecutor(8) as ex: prods = [p for p in ex.map(prod, range(1, NP + 1)) if p]
if not prods:  # NP=0: usar los productos que ya existen
    pg = 1
    while True:
        d = unwrap(req("GET", f"/products?limit=100&page={pg}", None, tok)[1])
        lst = d.get("data", d) if isinstance(d, dict) else d
        if not lst: break
        prods += lst; pg += 1
        if len(lst) < 100: break
print(f"productos {len(prods)} en {time.time()-t:.0f}s", flush=True); t = time.time()
with cf.ThreadPoolExecutor(8) as ex: custs = [c for c in ex.map(cust, range(1, NC + 1)) if c]
print(f"clientes {len(custs)} en {time.time()-t:.0f}s", flush=True); t = time.time()
json.dump({"products": [p["id"] for p in prods], "customers": [c["id"] for c in custs]}, open(OUT, "w"))
# Unos productos "calientes" concentran ventas (kardex largo, como en una tienda real)
hot = prods[:30]
def inv(i):
    items = []
    pool = hot if i % 3 == 0 else prods
    for p in random.sample(pool, min(len(pool), random.randint(1, 8))):
        pr = p.get("prices") or [{"amount": 1000}]
        items.append({"productId": p["id"], "description": p["name"], "quantity": random.randint(1, 4), "unitPrice": float(pr[0]["amount"])})
    credit = i % 5 == 0
    body = {"customerId": random.choice(custs)["id"], "items": items, "paymentMethod": "credit" if credit else "cash",
            "status": "pending" if credit else "paid", "taxPercentage": 0}
    if credit: body["metadata"] = {"isPureCreditInvoice": True}
    r = req("POST", "/invoices", body, tok)
    if i % 1000 == 0: print("  facturas", i, f"{time.time()-t:.0f}s", flush=True)
    return unwrap(r[1])["id"] if ok(r) else ("ERR " + str(r)[:200])
with cf.ThreadPoolExecutor(6) as ex: invs = list(ex.map(inv, range(1, NI + 1)))
good = [x for x in invs if not str(x).startswith("ERR")]
print(f"facturas {len(good)} ok, {len(invs)-len(good)} fallaron en {time.time()-t:.0f}s", [x for x in invs if str(x).startswith("ERR")][:3], flush=True)
# Proveedores + órdenes de compra (borrador, aprobadas y recibidas) y notas crédito (borrador y confirmadas)
sups = []
for i in range(20):
    r = req("POST", "/suppliers", {"name": f"Proveedor QA {RUN}-{i}", "documentType": "nit", "documentNumber": f"9{RUN}{i:05d}", "email": f"p{RUN}-{i}@qa.test"}, tok)
    if ok(r): sups.append(unwrap(r[1])["id"])
    elif i == 0: print("proveedor falló", r)
pos = 0
for i in range(300):
    if not sups or os.environ.get("QA_SKIP_PO"): break
    items = [{"productId": p["id"], "lineNumber": n + 1, "quantity": random.randint(5, 50), "unitCost": 700} for n, p in enumerate(random.sample(prods, min(len(prods), random.randint(3, 25))))]
    r = req("POST", "/purchase-orders", {"supplierId": random.choice(sups), "items": items, "expectedDeliveryDate": "2026-12-01"}, tok)
    if not ok(r):
        if i == 0: print("orden falló", r)
        continue
    pos += 1
print("órdenes de compra", pos, flush=True)
cns = 0
for inv_id in good[:400]:
    r = req("GET", f"/invoices/{inv_id}", None, tok); it = unwrap(r[1])["items"][0]
    r = req("POST", "/credit-notes", {"invoiceId": inv_id, "type": "partial", "reason": "returned_goods",
        "items": [{"invoiceItemId": it["id"], "productId": it.get("productId"), "description": it["description"], "quantity": 1, "unitPrice": float(it["unitPrice"])}],
        "restoreInventory": True}, tok)
    if not ok(r):
        if cns == 0: print("nota crédito falló", r)
        continue
    cns += 1
    if cns % 2 == 0: req("POST", f"/credit-notes/{unwrap(r[1])['id']}/confirm", {}, tok)
print("notas crédito", cns, flush=True)
