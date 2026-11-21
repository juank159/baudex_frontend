# Resume las consultas lentas de la base de PRUEBAS desde el log de Postgres
# (log_min_duration_statement + auto_explain activados SOLO en baudex_qa).
# Agrupa por forma de la consulta (sin valores) y da veces, total, p95 y peor.
# Uso: docker logs --since 30m ecommerce 2>&1 | python3 tool/estres/pg_slowlog.py [top] [--planes]
import re, sys, collections

top = int(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1].isdigit() else 25
show_plans = "--planes" in sys.argv
# --pids=archivo: solo procesos de Postgres conectados a la base de pruebas
# (el log del contenedor es compartido con otras bases). Se obtienen con:
#   psql -tAc "select pid from pg_stat_activity where datname='baudex_qa'"
pids = None
for a in sys.argv:
    if a.startswith("--pids="): pids = {l.strip() for l in open(a[7:]) if l.strip()}
head = re.compile(r"^\d{4}-\d\d-\d\d [\d:.]+ UTC \[(\d+)\] (\w+):\s+(.*)$")
dur = re.compile(r"duration: ([\d.]+) ms\s+(?:(?:execute|statement|parse|bind)[^:]*: )?(plan:)?(.*)$", re.S)

entries, cur = [], None
for line in sys.stdin:
    m = head.match(line.rstrip("\n"))
    if m:
        if cur: entries.append(cur)
        cur = [m.group(2), m.group(3)] if (pids is None or m.group(1) in pids) else None
    elif cur is not None and line.startswith("\t"):
        cur[1] += "\n" + line.rstrip("\n")[1:]
if cur: entries.append(cur)

def norm(q):
    q = re.sub(r"\s+", " ", q).strip()
    q = re.sub(r"'(?:[^']|'')*'", "?", q)
    q = re.sub(r"\$\d+", "?", q)
    q = re.sub(r"\b\d+(\.\d+)?\b", "N", q)
    q = re.sub(r"IN \((\?, )+\?\)", "IN (…)", q)
    return q[:400]

stats = collections.defaultdict(list)
plans = {}
for level, text in entries:
    if level != "LOG": continue
    d = dur.match(text)
    if not d: continue
    ms, is_plan, rest = float(d.group(1)), d.group(2), d.group(3)
    if is_plan:
        qt = re.search(r"Query Text: (.*?)\n", rest + "\n")
        if qt:
            k = norm(qt.group(1))
            if k not in plans or ms > plans[k][0]: plans[k] = (ms, rest.strip())
        continue
    stats[norm(rest)].append(ms)

def p(l, q):
    s = sorted(l); return s[min(len(s) - 1, int(round((len(s) - 1) * q)))]
rows = sorted(stats.items(), key=lambda kv: -sum(kv[1]))[:top]
print("| # | veces | total s | media ms | p95 ms | peor ms | consulta |")
print("|---|---|---|---|---|---|---|")
for i, (q, l) in enumerate(rows, 1):
    print(f"| {i} | {len(l)} | {sum(l)/1000:.1f} | {sum(l)/len(l):.0f} | {p(l,.95):.0f} | {max(l):.0f} | `{q[:220].replace('|','/')}` |")
if show_plans:
    for i, (q, l) in enumerate(rows[:10], 1):
        if q in plans:
            print(f"\n#### Plan de la consulta {i} ({plans[q][0]:.0f} ms)\n```\n{plans[q][1][:2500]}\n```")
