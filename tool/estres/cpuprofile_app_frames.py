# Atribuye el tiempo de CPU de un .cpuprofile de Node al código de la app
# (archivos dist/…) más cercano en la pila: dice QUÉ servicio paga el costo.
# Uso: python3 tool/estres/cpuprofile_app_frames.py perfil.cpuprofile [top]
import json, sys, collections, re
p = json.load(open(sys.argv[1])); top = int(sys.argv[2]) if len(sys.argv) > 2 else 20
nodes = {n["id"]: n for n in p["nodes"]}; parent = {}
for n in p["nodes"]:
    for c in n.get("children", []): parent[c] = n["id"]
counts = collections.Counter(p["samples"]); per = sum(p["timeDeltas"]) / len(p["samples"]) / 1000
def label(n):
    f = n["callFrame"]; return f"{f['functionName'] or '(anónima)'} {re.sub(r'.*/dist/', 'dist/', f['url'])}:{f['lineNumber']+1}"
deep, chain2 = collections.Counter(), collections.Counter()
for nid, c in counts.items():
    cur, app = nid, []
    while cur is not None:
        n = nodes[cur]
        if "/dist/" in n["callFrame"]["url"] and "node_modules" not in n["callFrame"]["url"]: app.append(label(n))
        cur = parent.get(cur)
    if nodes[nid]["callFrame"]["functionName"] in ("(idle)", "(program)", "(garbage collector)"): continue
    deep[app[0] if app else "(sin código de la app)"] += c * per
    if len(app) >= 2: chain2[" ← ".join(app[:3])] += c * per
total = sum(deep.values())
print(f"CPU ocupada atribuida: {total:.0f} ms")
for k, v in deep.most_common(top): print(f"{v:8.0f} ms {100*v/total:5.1f}%  {k}")
print("\n-- cadenas (función ← quien la llama ← …) --")
for k, v in chain2.most_common(10): print(f"{v:8.0f} ms  {k}")
