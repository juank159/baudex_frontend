#!/bin/bash
# Corre la prueba de estrés de la app de escritorio contra el servidor de PRUEBAS.
#   QA_STEPS=login,descarga,pos_escanear tool/estres/run_stress.sh <carpeta_salida>
# Requiere: app compilada con `flutter build macos --profile -t tool/estres/stress_main.dart`
# y el servidor de pruebas en 127.0.0.1:${QA_PORT:-3101}. HOME aislado: no toca
# los datos de la app real de este Mac (Isar, preferencias).
set -u
HERE="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${1:?carpeta de salida}"
mkdir -p "$OUT"
APP="$HERE/build/macos/Build/Products/Profile/baudex_desktop.app/Contents/MacOS/baudex_desktop"
QAHOME="${QA_HOME:-$OUT/baudex-qa-home}"
[ "${QA_FRESH:-0}" = 1 ] && rm -rf "$QAHOME"
mkdir -p "$QAHOME/Documents" "$QAHOME/Library/Application Support" "$QAHOME/Library/Caches" "$QAHOME/Library/Preferences"
MARK="$OUT/marca.txt"; : > "$MARK"
LOG="$OUT/app.log"
QA_MARK="$MARK" QA_OUT="$OUT/resultados.json" HOME="$QAHOME" CFFIXED_USER_HOME="$QAHOME" \
  "$APP" -NSAppSleepDisabled YES > "$LOG" 2>&1 &
APP_PID=$!
echo "app pid $APP_PID"
# Esperar la dirección del servicio de la VM y arrancar la sonda de memoria
for i in $(seq 1 120); do
  URI=$(grep -m1 -o 'VM_SERVICE http[^ ]*' "$LOG" | cut -d' ' -f2)
  [ -n "$URI" ] && break; sleep 0.5
done
# QA_NO_PROBE=1: sin sonda (la sonda fuerza recolección de basura cada 60 s y
# eso mete pausas falsas en los tiempos). Úsese la sonda solo para fugas.
if [ "${QA_NO_PROBE:-0}" = 1 ]; then
  echo "sin sonda de memoria"
elif [ -n "${URI:-}" ]; then
  (cd "$HERE" && dart run tool/estres/vm_probe.dart "$URI" "$APP_PID" "$MARK" "$OUT/memoria.jsonl" > "$OUT/sonda.log" 2>&1 &)
else
  echo "sin servicio de la VM (¿no es modo profile?)"
fi
# Muestreo de RSS con ps cada 5 s (independiente de la VM)
( while kill -0 $APP_PID 2>/dev/null; do echo "$(date +%H:%M:%S) $(ps -o rss= -p $APP_PID) $(cat "$MARK")" >> "$OUT/rss_ps.txt"; sleep 5; done ) &
wait $APP_PID
echo "salida app: $?"
grep 'QA|' "$LOG" | tail -40
