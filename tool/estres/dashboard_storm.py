# Tablero con C peticiones a la vez: ¿sobrevive el servidor? Mide tiempo y el
# pico de memoria (RSS) del proceso que escucha en el puerto de QA_URL.
# Uso: QA_URL=... python3 tool/estres/dashboard_storm.py 8 16
import sys, os, time, threading, subprocess, concurrent.futures as cf
sys.path.insert(0, os.path.dirname(__file__))
from qa_api import req, login, pct, B
port = B.split(":")[2].split("/")[0]
pid = subprocess.run(["lsof", "-tiTCP:" + port, "-sTCP:LISTEN"], capture_output=True, text=True).stdout.split()[0]
def rss():
    r = subprocess.run(["ps", "-o", "rss=", "-p", pid], capture_output=True, text=True).stdout.strip()
    return int(r) // 1024 if r else -1
tok = login("qa-dash")
today = time.strftime("%Y-%m-%d")
for C in [int(a) for a in sys.argv[1:]] or [8, 16]:
    for rango, start in (("hoy", today), ("mes", today[:8] + "01")):
        peak = [rss()]; base = peak[0]; stop = [False]
        def mon():
            while not stop[0]:
                v = rss(); peak[0] = max(peak[0], v); time.sleep(0.2)
        th = threading.Thread(target=mon); th.start()
        with cf.ThreadPoolExecutor(C) as ex:
            rs = list(ex.map(lambda _: req("GET", f"/dashboard/summary?startDate={start}&endDate={today}", None, tok, "qa-dash", timeout=300), range(C)))
        stop[0] = True; th.join()
        ms = [r[2] for r in rs]; codes = sorted({r[0] for r in rs})
        vivo = rss() > 0
        print(f"{C} a la vez · {rango}: códigos {codes} · p50 {pct(ms,.5):.0f} ms · peor {max(ms):.0f} ms · RSS {base} → pico {peak[0]} MB · servidor {'vivo' if vivo else 'CAÍDO'}", flush=True)
        if not vivo: sys.exit(1)
