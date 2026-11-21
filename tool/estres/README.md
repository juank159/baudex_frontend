# Prueba de estrés de Baudex (app de escritorio + servidor)

Todo corre contra un servidor de **pruebas** local y la base `baudex_qa`. Nada apunta a producción:
los guiones se niegan a correr si la URL no es `127.0.0.1`/`localhost`, y la app se niega si la
carpeta de documentos no es la aislada (`baudex-qa-home`).

## 1. Base y servidor de pruebas
- Base `baudex_qa` en el contenedor `ecommerce` (127.0.0.1:5432), usuario `baudex_qa`.
  Registro de consultas lentas solo en esa base: `log_min_duration_statement=100`, `auto_explain` ≥ 300 ms.
- Servidor (rama a medir) en el puerto 3101, sin `.env`, con `env -i` y solo las variables de
  `backend/.env.example` (DB_*, JWT_SECRET, PORT, NODE_ENV=test).
- Usuario: `qa@baudex.test` / `Prueba123!`, negocio "Tienda QA Estres 1fa9874b" (plan empresarial: 5 equipos).
  El servidor permite **una sesión por equipo** (`X-Device-Id`) y 5 equipos: si un guion falla con 403,
  apagar sesiones viejas: `update active_sessions set is_active=false`.

## 2. Volumen
`python3 tool/estres/seed_qa.py 5000 2000 20000` (productos, clientes, facturas por la API: crea kardex y
lotes de verdad) + 20 proveedores, 300 órdenes de compra y 400 notas crédito. `QA_DEV` distinto por guion.

## 3. App (macOS, modo profile)
```
flutter build macos --profile -t tool/estres/stress_main.dart
python3 tool/estres/prep_ids.py <salida>        # notas crédito en borrador y órdenes de compra frescas
QA_BUSINESS="Tienda QA Estres 1fa9874b" QA_CN_IDS=$(cat <salida>/cn_ids) QA_PO_IDS=$(cat <salida>/po_ids) \
QA_SNAPS=<salida>/fotos QA_NAV_N=100 tool/estres/run_stress.sh <salida>
```
- `stress_main.dart`: abre la app real; simula el lector de código de barras (teclas a 4 ms + Enter, por el
  mismo camino que el motor de macOS), atajos (Ctrl+=, Ctrl+N, Ctrl+-, flechas, Alt+6), ir y volver entre
  pantallas, confirmar notas crédito, órdenes de compra. El llavero es EN MEMORIA (no toca la sesión de la
  app real del Mac). Escenarios en `QA_STEPS` (ver el final del archivo).
- `vm_probe.dart` (lo arranca `run_stress.sh`): heap, RSS, objetos vivos por clase (controladores GetX,
  estados, temporizadores, avisos) y perfil de CPU por escenario (`cpu_<escenario>.txt`).
- Salida: `resultados.json` (una fila por escenario), `memoria.jsonl`, `rss_ps.txt`, `fotos/`.
- `vm_eval.dart <uri> [s]`: qué está haciendo la app ahora (CPU de los últimos s segundos).
- `vm_count.dart <uri> Clase1,Clase2`: instancias vivas tras recolección (p. ej. `GetPageRoute,AnimationController`).
- `vm_retain.dart <uri> <Clase>`: quién retiene esas instancias (camino hasta la raíz; así se halló
  `RouterReportManager._routesKey`).
- `hold_inventory_lock.sh <marca> <organization_id> [s]`: ocupa el candado de inventario del negocio al empezar el
  escenario de notas crédito (reproduce "error y luego confirmada").
- Aislamiento: HOME propio (Isar), llavero en memoria y preferencias en archivo propio `qa_prefs.json` (las preferencias de
  macOS NO respetan el HOME aislado y comparten archivo con la app real del Mac).

## 4. Servidor
- `api_load.py [concurrencia] [n]`: p50/p95/peor y tamaño de los endpoints que usan las pantallas.
- `cn_confirm_timing.py`: tiempo de confirmar notas crédito + doble confirmación simultánea (verifica en la base).
- `product_create_timing.py`: crear productos en la categoría más grande.
- `node_cpu_profile.dart` + `cpuprofile_app_frames.py`: perfil de CPU del servidor en marcha (`kill -USR1 <pid>`).
- `pg_slowlog.py --pids=<archivo>`: consultas lentas del log de Postgres, solo de los procesos de `baudex_qa`.

## 5. Prueba de la app sin servidor
`flutter test test/estres/snackbar_back_test.dart`: avisos en fila hacen que `Get.back()` no vuelva de pantalla.

## 6. Repetir "después" de los arreglos
- App con `-NSAppSleepDisabled YES` (ya lo pone `run_stress.sh`) y `QA_NO_PROBE=1` para medir tiempos; la sonda solo para fugas.
- Preferencias en un archivo propio (`<HOME aislado>/qa_prefs.json`, o `QA_PREFS_FILE`): no se toca el plist real.
- `QA_NO_FRAMES=1`: no guardar los `FrameTiming` (en 80 vueltas ocupan ~19 MB del heap y falsean la medición de memoria).
- En la versión con `AppNav.back` (rama `fix/estres-escaner-navegacion`) el "volver" de la prueba debe usar
  `AppNav.back()` en lugar de `Get.back()` (3 líneas en `stress_main.dart`: `back()`, ida y vuelta y bucle).
- Escenarios nuevos: `oc_apilada` (órdenes A/B apiladas), `alt_conserva_venta` (Alt+6/Alt+2 con venta a medias), `volver_con_avisos` (20 avisos en fila),
  `QA_IDA_SOLO_RUTA=1`.
- Servidor: `dashboard_storm.py 8 16`, `kardex_check.py`, `secret_leak_check.py` (con `QA_PSQL` de la base usada).
