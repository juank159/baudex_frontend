# Tiempo de crear productos en la categoría MÁS GRANDE (el servidor cargaba
# todos los productos de la categoría en cada creación). Uso:
#   QA_URL=... python3 tool/estres/product_create_timing.py [n=30]
import sys, os, time, shlex, subprocess
sys.path.insert(0, os.path.dirname(__file__))
from qa_api import req, unwrap, login, pct
n = int(sys.argv[1]) if len(sys.argv) > 1 else 30
PSQL = shlex.split(os.environ.get("QA_PSQL", "docker exec -i ecommerce psql -U baudex_qa -d baudex_qa"))
cid, cnt = subprocess.run(PSQL + ["-XAtc", 'select category_id, count(*) from products group by 1 order by 2 desc limit 1'], capture_output=True, text=True).stdout.strip().split("|")
tok = login("qa-prodtime")
ms = []
for i in range(n):
    c, d, t, _ = req("POST", "/products", {"name": f"Tiempo {time.time()}", "sku": f"TT{int(time.time()*1e6)%10**10}", "categoryId": cid, "stock": 5,
        "prices": [{"type": "price1", "name": "P", "amount": 1000}]}, tok, "qa-prodtime")
    if c in (200, 201): ms.append(t)
print(f"categoría con {cnt} productos · crear producto (1 a la vez): p50 {pct(ms,.5):.0f} ms p95 {pct(ms,.95):.0f} ms ({len(ms)}/{n} ok)")
