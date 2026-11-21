# ¿El kardex cuadra? Para los productos más movidos y unos al azar:
#   saldo inicial + entradas − salidas = saldo final  (aritmética del kardex)
#   saldo final del kardex = stock del producto = suma de lotes activos (base)
# Uso: QA_URL=... QA_PSQL="docker exec -i ecommerce psql -U baudex_qa -d <base>" python3 tool/estres/kardex_check.py [n=15]
import sys, os, shlex, subprocess
sys.path.insert(0, os.path.dirname(__file__))
from qa_api import req, unwrap, login
n = int(sys.argv[1]) if len(sys.argv) > 1 else 15
PSQL = shlex.split(os.environ.get("QA_PSQL", "docker exec -i ecommerce psql -U baudex_qa -d baudex_qa"))
def sql(q): return subprocess.run(PSQL + ["-XAtc", q], capture_output=True, text=True).stdout.strip()
ids = sql(f'''(select "productId" from inventory_movements group by 1 order by count(*) desc limit {n})
  union all (select id from products order by random() limit 5)''').split()
tok = login("qa-kardex")
ok = bad = err = 0
for pid in ids:
    c, d, ms, _ = req("GET", f"/reports/kardex/product/{pid}?startDate=2020-01-01&endDate=2027-12-31", None, tok, "qa-kardex")
    if c != 200: err += 1; print("ERROR", c, str(d)[:120]); continue
    k = unwrap(d)
    ini = float(k["initialBalance"]["quantity"]); fin = float(k["finalBalance"]["quantity"])
    ent = sum(float(m.get("entryQuantity") or m.get("quantityIn") or 0) for m in k["movements"])
    sal = sum(float(m.get("exitQuantity") or m.get("quantityOut") or 0) for m in k["movements"])
    stock = float(sql(f"select stock from products where id='{pid}'") or "nan")
    lotes = float(sql('select coalesce(sum("currentQuantity"),0) from inventory_batches where "productId"=\'' + pid + "' and status='active'") or "nan")
    arit = abs(ini + ent - sal - fin) < 0.001
    cuadra = arit and abs(fin - stock) < 0.001 and abs(stock - lotes) < 0.001
    ok += cuadra; bad += not cuadra
    if not cuadra or ids.index(pid) < 3:
        print(f"{'ok ' if cuadra else 'NO '} {k['product']['sku']}: movs={len(k['movements'])} inicial={ini:g} +{ent:g} −{sal:g} = final {fin:g} · stock {stock:g} · lotes {lotes:g} · {ms:.0f} ms")
print(f"kardex que cuadran: {ok}/{ok+bad} (errores HTTP {err})")
