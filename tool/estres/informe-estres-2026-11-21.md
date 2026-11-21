# Prueba de estrés de Baudex — 21 de noviembre de 2026 (noche)

**Qué se probó:** la app de escritorio real (macOS, modo *profile*) y el servidor NestJS, contra una base de
PRUEBAS (`baudex_qa`) con volumen de tienda grande. Nada tocó producción.
**Veredicto:** **devuelto** a flutter-dev y backend-nest — se reprodujeron **los 4 errores reportados** (3 con la causa
demostrada en código, el de órdenes de compra solo en parte) y aparecieron **9 errores nuevos**, tres graves: el servidor
se cae por memoria con el tablero, una nota crédito se aplica dos veces, y con el catálogo completo el lector pierde
escaneos (43 de 100).

---

## 0. Resumen para el CEO
1. **Lector + factura grande:** con 5 mil productos y 20 mil facturas en el equipo, **43 de 100 re-escaneos no entraron**
   en 15 s (peor 24 s) y la app se quedó **7,9 s sin responder**; la caja de búsqueda pierde el foco cada ~15 escaneos y
   las teclas del lector se pierden.
2. **"Al volver a la factura se congela":** cada escaneo repetido pone un aviso verde; quedan **93 avisos en fila** (4 min)
   y mientras haya uno, *volver* solo cierra el aviso (hasta **42 s** para volver). Con el catálogo completo, al volver,
   el Enter del lector no entra y **los códigos se pegan** en la caja (p95 18 s por escaneo).
3. **Nota crédito "error y luego confirmada":** reproducido tal cual. Con el servidor ocupado 40 s: la app espera 30 s,
   dice "Error inesperado" y la nota sigue en borrador en pantalla; el servidor la confirma 11 s después. Y al abrir la
   siguiente nota, la pantalla muestra **la anterior** (7 de 7). En el servidor, dos "confirmar" a la vez la aplican **dos
   veces** (stock y saldo dobles) — ya corregido en la rama del dba.
4. **El tablero tumba el servidor:** 1 consulta = 4–8 s y ~500 MB; con 8 a la vez el servidor murió por memoria
   (todos los negocios sin servicio). No está corregido en ninguna rama.
5. **Memoria de la app:** sin fugas en los controladores, pero GetX **retiene cada pantalla cerrada desde el menú**
   (398 rutas vivas tras 1 h; heap 36 → 63 MB). Crece sin límite mientras la app esté abierta.

---

## 1. Entorno y volumen

| | |
|---|---|
| Base | `baudex_qa` (Postgres 15, contenedor `ecommerce`, 127.0.0.1:5432), creada vacía con las 66 migraciones del servidor (en `ecommerce` no había base de Baudex; `inv-test-pg` comparte puerto con `ops-test-pg` y no se pudo levantar). Registro de lentas SOLO en esa base: `log_min_duration_statement=100`, `auto_explain` ≥ 300 ms. `pg_stat_statements` NO: exige reiniciar el contenedor (lo usa Agendity). |
| Volumen (sembrado por la API, así se crean kardex y lotes reales) | 5.035 productos · 2.031 clientes · 19.681 facturas (88.093 líneas, 15.710 pagos) · 93.361 movimientos de inventario · 600 órdenes de compra · 453 notas crédito · 167 MB |
| Servidor | `backend/dist` de `main` (73f0f86) en el puerto **3101**, `env -i` sin `.env`, heap 2 GB. "Después": rama `perf/consultas-y-nota-credito` (dba, PR #14) en el **3131** sobre una copia `baudex_qa_despues`. |
| App | `frontend` `main` (8af93bf) en la rama `test/estres-qa`, compilada `--profile` con `tool/estres/stress_main.dart`; HOME aislado (`baudex-qa-home`) y llavero en memoria. |
| Medición | sonda por el servicio de la VM (heap, RSS, objetos vivos por clase cada 60 s y en cada cambio de escenario, perfil de CPU por escenario), cuadros (`FrameTiming`), reloj de 16 ms para pausas del hilo, `ps` cada 5 s, fotos de pantalla. |

Atención: el volumen se sembró en una sola noche, así que **las 19.681 facturas son "de hoy"**. El tablero de "hoy"
equivale al de un mes de una tienda con ~650 facturas diarias.

---

## 2. Errores reportados

### 2.1 Factura + lector de código de barras con muchas líneas: lentitud — **reproducido en parte**
Pasos: abrir *Facturas con pestañas*, escanear 150 códigos distintos (13 teclas a 4 ms + Enter), luego 100 re-escaneos
de los mismos 10, luego atajos.

| Medición | Resultado |
|---|---|
| Escaneo → línea en la factura (catálogo ya en el equipo) | p50 **101 ms**, p95 116 ms, peor 131 ms; las primeras 20 y las últimas 20 líneas tardan igual (no crece con el número de líneas) |
| Mismo escaneo **mientras la app descarga cambios del servidor** (corrida 1) | p95 261 ms, **peor 3.598 ms**; 5 cuadros congelados > 500 ms (peor 3.366 ms), hilo principal parado hasta **2.743 ms** |
| **Catálogo completo (5.065 productos, 19.681 facturas en el equipo, corrida 4)** | 150 escaneos: p50 138 ms, p95 176, peor 407; 3 cuadros > 500 ms (peor 2,6 s). **100 re-escaneos: 43 no entraron en 15 s**, p50 308 ms, p95 **17,6 s**, peor 23,8 s; la app sin responder hasta **7,9 s** |
| Atajos Ctrl+= (100), Ctrl+5 (50), Ctrl+- (30) | 180/180 aplicados, < 10 ms cada uno |
| Atajo con teclado español | Ctrl + tecla "+" (`LogicalKeyboardKey.add`), Ctrl + "+" y "-" del teclado numérico: **no hacen nada** (ver §3.5) |
| **El foco se pierde** | la caja de búsqueda perdió el foco 8 veces en 150 escaneos (corrida 1) y 6 en 100 re-escaneos (corrida 2); el foco quedó en el `FocusScopeNode` (nadie). Con un lector real **esas teclas se pierden** (el cajero cree que la app no responde). La prueba devolvió el foco para seguir midiendo. |
| Avisos en fila | cada re-escaneo pone un `Get.snackbar` de 2 s ("🎯 Producto Actualizado", invoice_form_controller.dart:2522): 100 re-escaneos → **93 avisos en fila**, se vaciaron en ~4 min (sonda: `SnackbarController` 93 → 0 de 01:33:51 a 01:37:59). |

Causa del foco perdido: `ProductSearchWidget._onFocusChanged` (product_search_widget.dart:97-117) solo recupera el foco
si `primaryFocus` es nulo o es la propia caja; cuando el foco cae al `FocusScopeNode` (lo que pasa cuando la pantalla se
reconstruye por la sincronización o por el aviso), `primary != _focusNode` y **no lo recupera nunca**.
Causa de los saltos de 1–8 s: la sincronización en segundo plano sigue trabajando en el hilo principal después de la
descarga (60 s "quieto" tras descargar: peor cuadro 2,7 s; 93 mil movimientos de inventario y 4 MB por cada 500 facturas,
ver §5). La causa exacta de los 43 escaneos perdidos no quedó aislada: la cola de escaneos (`BarcodeScanQueue`) procesa
uno a la vez y espera `findProductByBarcode`; si esa búsqueda tarda, todos los siguientes esperan. **A confirmar por
flutter-dev con el perfil de la corrida 4** (`cpu_pos_reescanear_mismos.txt`).

### 2.2 Factura abierta → Productos → escanear en el buscador → volver: se congela — **reproducido, causa demostrada**
Pasos (15 vueltas, mitad con Alt+6, mitad por ruta): factura con 150 líneas y avisos en fila → Productos → 3 escaneos en
el buscador → volver → escanear en la factura.

| Medición | Resultado |
|---|---|
| Volver a la factura | p95 **30,4 s**, peor **42 s** (corrida 2). Foto `factura_tras_volver`: la app seguía en Productos. |
| Escanear en el buscador de Productos | la pantalla no se queda quieta en 20 s (aviso animándose encima) |
| Escaneo en la factura después de volver | corridas 2–3: p95 118–158 ms. **Corrida 4 (catálogo completo): p95 18 s**; foto `015_lento_escanear_al_volver`: el Enter no llegó a la caja y **los códigos quedaron pegados** ("No se encontraron productos para '7762…1026…1027…'") |

Causa: `Get.back()` de GetX 4.7.3 (extension_navigation.dart:825) **solo cierra el aviso abierto y no vuelve** si hay un
snackbar. Con 90 avisos en fila, el botón volver "no hace nada" durante minutos → parece congelada. Prueba sin
servidor que lo demuestra: `test/estres/snackbar_back_test.dart` (pasa: 5 × `Get.back()` con avisos en fila y la ruta
sigue en Productos). No es el escáner en sí ni la búsqueda: el buscador de Productos responde (p95 < 300 ms en servidor).

### 2.3 Confirmar nota crédito en borrador: lento, muestra error y luego aparece confirmada — **reproducido exacto**
**Reproducción (corrida 4):** mientras otra operación tiene ocupado el inventario del negocio 40 s
(`tool/estres/hold_inventory_lock.sh`, lo mismo que una venta o una creación de producto lentas), se confirma CN-2026-0454
en la app: espera **30.040 ms**, aparece en rojo *"Error — Error inesperado al confirmar nota de crédito"* y la nota sigue en
**Borrador** (foto `025_nota_credito_error_…`). En la base: `status=confirmed`, `applied_at` 08:35:47 UTC — justo cuando se
soltó el candado, 11 s después del error. Inventario devuelto 1 vez (1 movimiento para 1 línea). La pantalla muestra
además "Cliente no encontrado" y "Factura N/A · $ 0" para una nota que sí tiene cliente y factura.
Por qué pasa:
1. **"Error inesperado" ante cualquier falla.** `CreditNoteRemoteDataSource.confirmCreditNote`
   (credit_note_remote_datasource.dart:231-269) espera `DioException`, pero `DioClient` ya la convirtió en
   `ServerException`/`ConnectionException`; el `catch (e)` final la cambia por *"Error inesperado al confirmar nota de
   crédito"*. Consecuencias: (a) el respaldo sin internet del repositorio (`if (e is ConnectionException)`,
   credit_note_repository_impl.dart:441) **nunca se ejecuta**; (b) si el tiempo se agota (30 s) pero el servidor termina
   después, la app dice error y la nota "aparece confirmada" en la siguiente sincronización. Visto en el log de la app:
   13 veces "Error al confirmar nota de crédito: Error inesperado…".
2. **La pantalla muestra otra nota.** Tras confirmar una nota, *volver* se gasta en el aviso verde "Confirmada"; al abrir
   la siguiente nota, el controlador (`Get.lazyPut` sin etiqueta) es el de la nota anterior: la app mostró 7 notas como
   "confirmadas" que en la base seguían en **borrador** (CN-2026-0047 a 0053), y "Confirmar" sobre ellas da error
   (porque reconfirma la anterior). Corrida 4: `pantalla_muestra_otra_nota` 7 de 7 y *volver* sin efecto 8 veces.
3. **Lento con carga:** `POST /credit-notes/:id/confirm` p50 885 ms, p95 **3.337 ms** mientras se facturaba (espera el
   candado de inventario del negocio). Sin carga: 146 ms en la app.
4. **Doble aplicación (servidor) — ver §3.2.**

### 2.4 Orden de compra en borrador → Productos → volver → abrir su detalle: se congela o se cierra — **no se reprodujo el cierre; sí dos fallas relacionadas**
6 órdenes × 4 variantes (detalle→Alt+6 Productos→volver; volver a abrir desde la lista; detalle→Productos→detalle de otra
orden encima; formulario nuevo→Productos→volver→detalle). Sin excepciones ni cierres. Pero:
- **Detalle apilado muestra la orden equivocada** en 6 de 6: al abrir el detalle de la orden B encima de la A, se ve la
  A (mismo `PurchaseOrderDetailController` sin etiqueta, purchase_order_detail_binding.dart:31). Al cerrar una de las dos
  se borra el controlador que la otra aún usa.
- **Las pantallas de órdenes nunca quedan quietas** (lista y detalle pintan cuadros sin parar: el botón "+" con brillo
  animado). Cada apertura "termina" solo por el tope de 8 s de la prueba. Gasta CPU todo el tiempo.
- La lista dice **"0 órdenes de compra · Página 1 de 0"** mientras muestra órdenes (foto 018).
- Combinado con 2.2 (volver que no vuelve si hay aviso), el usuario puede terminar en el detalle equivocado.

---

## 3. Errores nuevos

### 3.1 El servidor se cae por memoria con el tablero (crítico)
`GET /dashboard/summary` → `ProfitabilityService.getProfitabilityStats` (src/common/services/profitability.service.ts:72-98)
trae todas las facturas del período con líneas + producto + categoría como entidades y suma en JavaScript.
- 1 petición: **4.012 ms**, el proceso pasa de 125 MB a **616 MB**.
- 8 a la vez: `FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory` (02:02, log
  `backend-1-oom.log`). Todos los negocios quedan sin servidor hasta que Docker lo reinicie.
- 2 a la vez: p50 8,8 s, p95 18,5 s. La rama del dba no lo cambia (8,2 s).

### 3.2 Nota crédito aplicada dos veces (crítico, datos)
`CreditNotesService.confirm` (src/credit-notes/services/credit-notes.service.ts:166) revisa `status === DRAFT` fuera de la
transacción, sin bloquear la fila. Dos POST `/confirm` simultáneos → 200 y 200; en la base: **2 movimientos
`return_in`** (stock devuelto dos veces) y `invoices.credited_amount` = **11.200 para una nota de 5.600** (repetido 2/2).
Pasa en la vida real con un doble clic o con el reintento de la sincronización. **En la rama del dba ya no pasa**
(1 movimiento, 5.600/5.600, la segunda confirmación responde 200 sin repetir).
Guion: `tool/estres/cn_confirm_timing.py`.

### 3.3 Crear producto carga toda la categoría (alto, todos los negocios)
`CategoriesService.findOne` (categories.service.ts:426) trae `relations: ['parent','children','products']` y
`ProductsService.create` (products.service.ts:102) se la pasa a `productRepository.create`: 82 % de la CPU del servidor en
`OrmUtils.mergeDeep`. Crear producto: **1.049 ms** (p95 1.105) con 1.871 productos en la categoría; durante la siembra
(8 a la vez) el servidor estuvo al 100 % y bajó a 3,3 productos/s. Rama del dba: **30 ms** (p95 65).

### 3.4 Kardex siempre en cero
La pantalla de kardex llama `/reports/kardex/product/:id` → 400 (`Property "createdBy" was not found in
"InventoryMovement"`); la app muestra *Existencia inicial 0, Entradas +0* para un producto con 99.997 unidades (foto 016).
`/inventory/products/:id/kardex` también da 400. Arreglado en la rama del dba (200, 59 ms).

### 3.5 Atajos con teclado en español
El atajo de sumar es `Ctrl + =` (`LogicalKeyboardKey.equal`, invoice_form_screen.dart:141). En un teclado latinoamericano
o español la tecla "+" produce el carácter `+` (`LogicalKeyboardKey.add`) y el "+" del teclado numérico es `numpadAdd`:
ninguno está atendido → **Ctrl++ no hace nada en el teclado del cliente** (verificado en la corrida 4, §4).

### 3.6 GetX retiene cada pantalla cerrada desde el menú (fuga de memoria)
`Get.offAllNamed` (menú lateral, Alt+1) deja las rutas quitadas en `static RouterReportManager._routesKey` (get 4.7.3):
398 rutas vivas tras el bucle, `AnimationController` 108 → 925, heap 36 → 63 MB. Detalle en §6.

### 3.7 La descarga inicial puede quedar incompleta para siempre (marcas de sincronización fuera de la base local)
Las marcas de "hasta dónde bajé" (`sync_wm_v1|<negocio>|<módulo>`, sync_changes_client.dart:120) se guardan en las
preferencias del sistema, no junto a la base Isar. Si la base local se pierde o se recrea (reinstalar, borrar la carpeta,
base dañada) y las preferencias quedan, la app cree que ya tiene todo y solo baja los cambios nuevos: en la corrida 3 el
equipo quedó con **52 productos y 1 factura de 5.035 / 19.681 durante 1 h**, sin ningún aviso. Para clientes sí hay un
control ("el equipo tiene 0 y el servidor 2031 — se descarga todo de nuevo"); para productos y facturas no.
(Lo destapó una falla de la propia prueba: ver §8, "preferencias compartidas".)

### 3.8 El lector pega los códigos al volver de Productos (catálogo completo)
Corrida 4, 15 vueltas: al volver a la factura el Enter del lector no llegó a la caja y los siguientes códigos se
concatenaron (foto `015`): escanear al volver p95 **18 s**, la app sin responder hasta **6,5 s**. Pista: algún manejador
de teclado se queda con el Enter (el `Focus.onKeyEvent` de product_search_widget.dart:300 lo toma si cree que hay un
resultado elegido; el manejador global de la factura decide "es un TextField" comparando `toString()` del widget con foco).
**A confirmar por flutter-dev.**

### 3.9 Otros
- `/inventory/summary` → 400 `column product.isactive does not exist` (la app no lo usa hoy).
- `/inventory/balances` devolvía **1,3 MB por página de 50** (no paginaba). Rama del dba: 13 KB.
- La pantalla de Inventario, Kardex, Productos (con aviso) y Órdenes **nunca dejan de pintar** (> 8–15 s sin quietud):
  animaciones sin fin = CPU y batería todo el día.
- El servidor escribe ~1,1 millones de líneas de log en 1 h 25 min de carga (111 MB; `console.log` por venta y por nota).
- El candado de inventario por negocio (`movement_number_<org>`, movement-number.ts:58) serializa ventas y productos:
  6.433 esperas en 20 min, p95 1,9 s, peor **13,6 s**. Máximo medido: ~10 facturas/s por negocio.

---

## 4. Escenarios en la app: antes de los arreglos (corridas 2, 3 y 4)

> RSS por `ps`; heap tras forzar recolección (sonda de la VM). "Cuadros congelados" = cuadros de más de 500 ms.

| corrida | escenario | duración | RSS MB (antes→después) | cuadros / >50 ms / >500 ms | peor cuadro | mayor pausa del hilo | resultado |
|---|---|---|---|---|---|---|---|
| 4 | Descarga inicial (equipo nuevo) | 72 s | 163→319 | 3750 / 97 / **3** | 1059 ms | 1069 ms | 5065 productos, 2031 clientes, 19681 facturas en 72 s |
| 4 | 60 s quieto tras la descarga | 60 s | 403→250 | 3206 / 56 / **3** | 2690 ms | 1652 ms | la sincronización de fondo sigue trabando la pantalla |
| 1 | 150 escaneos mientras baja datos | 31 s | 76→103 | 1060 / 47 / **5** | 3366 ms | 2743 ms | p50 104 / p95 261 / peor 3598 ms · foco perdido 8 |
| 2 | 150 escaneos (catálogo parcial) | 19 s | 240→111 | 964 / 3 / **2** | 1588 ms | 1398 ms | p50 101 / p95 116 / peor 131 ms · foco perdido 1 |
| 4 | 150 escaneos (catálogo completo, 20 mil facturas) | 27 s | 453→219 | 1193 / 15 / **3** | 2568 ms | 1215 ms | p50 138 / p95 176 / peor 407 ms · foco perdido 9 |
| 2 | 100 re-escaneos (150 líneas) | 12 s | 170→164 | 713 / 1 / **0** | 131 ms | 140 ms | p50 109 / p95 148 ms · perdidos 0 · 93 avisos en fila |
| 4 | 100 re-escaneos (catálogo completo) | 765 s | 217→217 | 8968 / 49 / **2** | 646 ms | 7934 ms | **43 de 100 no se aplicaron en 15 s** · p50 308 / p95 17592 / peor 23837 ms |
| 4 | Atajos (180) + 100 flechas | 10 s | 403→193 | 93 / 2 / **0** | 63 ms | 447 ms | 180/180 aplicados, < 10 ms; Ctrl+"+" español y numérico: NO HACEN NADA |
| 2 | Factura ↔ Productos ×15 (con avisos en fila) | 254 s | 152→203 | 12682 / 24 / **1** | 1484 ms | 1476 ms | volver a la factura p95 1.0 s / peor **42 s** |
| 3 | Factura ↔ Productos ×15 | 290 s | 159→165 | 15287 / 6 / **1** | 1029 ms | 1047 ms | volver p95 30.4 s; Productos nunca queda quieta (17/15) |
| 4 | Factura ↔ Productos ×15 (catálogo completo) | 334 s | 140→263 | 1406 / 53 / **3** | 2418 ms | 6500 ms | volver p95 1082 ms pero **escanear al volver p95 18 s**: los códigos se pegan en la caja (foto) |
| 2 | Búsquedas (controlador, Isar) | 1 s | 290→191 | 2 / 0 / **0** | 31 ms | 46 ms | productos 0–44 ms, clientes 7–32 ms |
| 2 | Abrir/cerrar 30 detalles de factura | 57 s | 164→168 | 1460 / 1 / **0** | 86 ms | 93 ms | abrir p50 879 ms (incluye 400 ms de espera de quietud) |
| 2 | Kardex ×5, saldos, movimientos, inventario | 46 s | 357→218 | 2226 / 17 / **0** | 489 ms | 110 ms | kardex 2,7 s la 1.ª vez y ~0,4 s después — muestra CEROS (400 del servidor); Inventario nunca queda quieto |
| 4 | Confirmar 8 notas (servidor ocupado 40 s en la 1.ª) | 76 s | 264→281 | 2954 / 23 / **5** | 2311 ms | 8899 ms | 1.ª: 30 s y "Error inesperado", el servidor la confirma 11 s después; las otras 7: la pantalla muestra OTRA nota; volver sin efecto 8 veces |
| 3 | Órdenes de compra ×6 (4 variantes) | 633 s | 242→160 | 36909 / 15 / **0** | 204 ms | 125 ms | sin cierres; detalle apilado muestra la orden equivocada 6/6; lista y detalle nunca quedan quietos |
| 3 | Bucle 100 vueltas × 10 pantallas (1.000 aperturas) | 2340 s | 325→135 | 121421 / 206 / **7** | 1015 ms | 1017 ms | heap 36→63 MB; rutas retenidas por GetX (ver §6) |

Notas de lectura:
- Corrida 1 (01:20): servidor ocupado sembrando, la app bajando datos. Corrida 2 (01:32): catálogo parcial en el equipo.
  Corrida 3 (02:11–03:09): equipo SIN catálogo (ver §3.7, falla de la propia prueba que reveló un error real) + bucle largo.
  Corrida 4 (03:13–03:36): equipo nuevo con TODO descargado (5.065 productos, 19.681 facturas) — la más fiel a una tienda grande.
- En la corrida 4 la prueba consultaba la factura cada 20 ms con `Get.isRegistered` (≈25 % del hilo principal en el
  re-escaneo). Ya está corregido en la rama, pero las cifras de re-escaneo de esa corrida pueden estar algo infladas; los
  43 escaneos perdidos y la pausa de 7,9 s no se explican por eso (cada consulta dura microsegundos).
- "Mayor pausa del hilo" = el reloj de 16 ms no pudo latir durante ese tiempo: la app no responde a nada.


---

## 5. Servidor: endpoints y consultas

### 5.1 Endpoints que usan las pantallas
`tool/estres/api_load.py 8 40`: 8 peticiones a la vez, 40 por endpoint (tablero: 2 a la vez, 6 peticiones, porque con 8 se cae).
"Antes" = `main` en el 3101; "después" = rama `perf/consultas-y-nota-credito` (PR #14 del dba) en el 3131 con una copia de la misma base.

| endpoint | antes p50/p95 ms (KB) | después p50/p95 ms (KB) |
|---|---|---|
| GET /products (lista 50) | 200 680/5920 (74) | 200 152/216 (74) |
| GET /products?search= | 0,200 129/157 (27) | 200 75/86 (30) |
| GET /products/search | 200 84/110 (17) | 200 73/92 (17) |
| GET /products/barcode/:code | 200 37/45 (2) | 200 33/38 (2) |
| GET /products/:id | 200 40/51 (2) | 200 34/40 (2) |
| GET /customers (lista 50) | 200 37/51 (32) | 200 29/38 (32) |
| GET /customers/search | 0,200 23/30 (0) | 200 21/25 (0) |
| GET /invoices (lista 50) | 200 638/1160 (425) | 200 213/822 (425) |
| GET /invoices?search= | 200 147/167 (118) | 200 117/184 (110) |
| GET /invoices/:id | 200 54/66 (8) | 200 75/193 (8) |
| GET /invoices/stats | 200 72/88 (0) | 200 69/157 (0) |
| GET kardex producto vendido | 400 37/48 (0) | 200 59/109 (1) |
| GET /inventory/balances | 200 228/384 (1345) | 200 67/150 (13) |
| GET /inventory/movements | 200 267/325 (48) | 200 41/52 (48) |
| GET /inventory/stats | 200 460/590 (0) | 200 552/1015 (0) |
| GET /inventory/summary | 400 21/25 (0) | 400 20/39 (0) |
| GET /purchase-orders | 200 47/61 (97) | 200 51/62 (97) |
| GET /purchase-orders/:id | 200 32/37 (20) | 200 35/48 (21) |
| GET /credit-notes | 200 63/80 (158) | 200 59/74 (158) |
| GET /credit-notes/:id | 200 34/40 (5) | 200 34/42 (5) |
| GET /dashboard/summary hoy | 200 8789/9462 (2) | 200 8216/10094 (2) |
| GET /dashboard/summary mes | 200 8491/18459 (3) | 200 6357/10134 (3) |
| GET /sync/changes/products (desde 0) | 200 1176/1791 (747) | 200 1080/1777 (747) |
| GET /sync/changes/invoices (desde 0) | 200 1381/1529 (4179) | 200 1409/1611 (4179) |
| GET /sync/changes/inventory_movements | 200 186/266 (458) | 200 180/241 (458) |


- **Lo más lento que queda después de la rama del dba:** tablero (6–10 s y ~500 MB por petición), `/sync/changes/*` desde cero
  (1,1–1,4 s y **4,2 MB por cada 500 facturas**: un equipo nuevo baja ~170 MB para 20 mil facturas), `/inventory/stats` (0,5–1 s),
  `/invoices` lista (p95 0,8 s y **425 KB por página de 50**: cada factura trae todo su detalle).
- Crear producto (1 a la vez, categoría de 1.871 productos): antes **1.049 ms** p50 / 1.105 p95 → después **30 ms** / 65.
- Confirmar nota crédito: antes p50 885 ms / p95 3.337 ms con ventas en curso; después 28 / 73 ms (sin ventas en curso: no es comparable 1 a 1).

### 5.2 Consultas lentas (log de Postgres, solo procesos de baudex_qa)
| consulta | veces | media | p95 | peor | de dónde viene |
|---|---|---|---|---|---|
| `SELECT pg_advisory_xact_lock(hashtext('movement_number_<org>'))` | 6.433 en 20 min | 282 ms | 1.892 ms | 9.634 ms | candado de inventario por negocio: cada venta/producto espera a la anterior (con 6 cajas a la vez: p95 2,9 s, peor 13,6 s) |
| `SELECT invoice.* … LEFT JOIN items, product, category` (rentabilidad del tablero) | 12 en 18 min (la app vuelve al tablero) | 4.973 ms | 5.582 ms | 7.878 ms | 88.114 filas × 2 KB; la consulta en Postgres tarda 0,9 s, el resto es transferir y armar entidades en Node |
| `SELECT * FROM ( -- Cobros de facturas …` (desglose de cobros del tablero) | 2 | 768 ms | 1.327 ms | 1.327 ms | tablero |
| `SELECT "movementNumber" … ~ regex ORDER BY … DESC LIMIT 1` | 3.360 | 2 ms | 0 | 154 ms | numeración de movimientos (bien con el índice) |

Perfil de CPU del servidor (`tool/estres/node_cpu_profile.dart` sobre el proceso en marcha):
- Creando productos: **82 %** en `ProductsService.create` → `OrmUtils.mergeObjectKey/mergeDeep` de TypeORM (la categoría con todos sus productos).
- Facturando (6 a la vez): el servidor al 40 % de CPU; el cuello es el candado por negocio, no la CPU. Lo más caro propio:
  `ProductsService.findOne` por cada línea (5 %), `registerSale`/`consumeStockDynamic` (FIFO).
- Conexiones: el pool abre y cierra conexiones sin parar (660 procesos distintos de Postgres en 18 min).


---

## 6. Memoria y fugas

**Fuga encontrada: GetX guarda para siempre cada pantalla cerrada con `offAllNamed`.**
- Sonda (heap tras recolección, mismo punto del bucle): **36,5 MB → 63,1 MB** en 90 vueltas del bucle de navegación
  (vuelta 0: 39,3 · 30: 42,9 · 60: 58,4 · 90: 63,1); `AnimationController` vivos **108 → 925**; `GetPageRoute` vivos **387 → 404 en 60 s** mientras el navegador tenía solo
  3–5 pantallas abiertas; `OverlayEntry` 774 → 809.
- Camino de retención (`tool/estres/vm_retain.dart`): 398 de 400 rutas vivas cuelgan de
  **`static RouterReportManager._routesKey`** (get 4.7.3). Las rutas quitadas con `Get.offAllNamed` (lo que usa el menú
  lateral, `AppNav.offAllNamed`, y Alt+1 al tablero) nunca se reportan como cerradas, así que el mapa estático las retiene
  con su animación, sus entradas del overlay y parte del árbol de widgets.
- Ritmo medido: ~0,3 MB de heap y ~8 rutas por vuelta de 10 pantallas. Una cajera que navega por el menú todo el día
  acumula decenas de MB y miles de objetos; no tumba la app en una jornada, pero crece sin límite hasta cerrarla.
- Arreglo: navegar desde el menú con `Get.until`/`Get.toNamed` + `Get.offNamedUntil`, o limpiar con
  `RouterReportManager.instance.reportRouteDispose` en un `NavigatorObserver.didRemove`; o subir de versión de GetX si ya
  está corregido (verificar).

**Sin fuga en controladores GetX de pantallas:** `InvoiceFormController`, `ProductsController`, `PurchaseOrdersController`,
`PurchaseOrderDetailController`, `CreditNoteDetailController` se mantienen en 0–2 instancias durante todas las corridas
(sonda cada 60 s). `Timer` vivos estables (9–22). `GetStream` estable (~199) salvo picos al abrir pantallas.

**Avisos en fila (no es fuga, pero sí acumulación):** `SnackbarController` 0 → **93** tras 100 re-escaneos; se vacían en ~4 min.

**RSS del proceso (`ps`):** entre 65 y 506 MB según la pantalla y las imágenes en caché; sube y baja, sin tendencia
clara en 1 h de navegación (corrida 3: 92–293 MB). Heap de Dart tras recolección: 32–67 MB.

**Animaciones que nunca paran** (la pantalla no queda quieta ni en 8–15 s): Tablero (21 de 21 veces), Órdenes de compra
lista y detalle, Kardex, Inventario, Productos (mientras hay avisos), Facturas con pestañas. En la corrida 3, 52,9 s de CPU
del hilo de Dart en 633 s de órdenes de compra; `Ticker._tick` ≈ 16 % de ese tiempo.


---

## 7. Arreglos en orden de prioridad

| # | Qué | Quién | Por qué primero |
|---|---|---|---|
| 1 | Tablero: calcular rentabilidad con SQL (`SUM … GROUP BY`) en vez de cargar entidades | backend-nest | tumba el servidor de TODOS |
| 2 | Nota crédito: confirmar idempotente con bloqueo de fila y `credited_amount = credited_amount + x` en SQL | backend-nest (ya en PR #14 — falta fusionar y probar en la app) | dinero e inventario dobles |
| 3 | App: no usar `Get.snackbar` por cada escaneo repetido (un solo aviso que se reemplaza, o `closeAllSnackbars()` antes), y volver con `Navigator.pop`/`Get.back(closeOverlays: true)` | flutter-dev | "se congela al volver" |
| 4 | App: lector — `ProductSearchWidget._onFocusChanged` debe recuperar el foco también cuando `primaryFocus` es un `FocusScopeNode`; averiguar quién se queda con el Enter al volver de Productos (§3.8) y por qué se pierden escaneos con el catálogo completo (§2.1) | flutter-dev | el lector pierde y pega códigos |
| 5 | App: `confirmCreditNote` del datasource — quitar el `catch (e)` genérico; ante tiempo agotado, preguntar al servidor el estado real de la nota antes de decir "error" | flutter-dev | "error y luego confirmada" |
| 6 | App: controladores de detalle (nota crédito, orden de compra) con `tag` por id o `Get.create` | flutter-dev | se muestra el registro equivocado |
| 7 | App: navegación del menú sin `offAllNamed` (o limpiar `RouterReportManager`) | flutter-dev | fuga de memoria (§3.6) |
| 8 | App: guardar las marcas de sincronización en la base Isar (o comparar conteos de productos/facturas como ya se hace con clientes) | flutter-dev | equipo con catálogo incompleto sin saberlo (§3.7) |
| 9 | Crear/editar producto sin cargar los productos de la categoría | backend-nest (ya en PR #14) | 35× más rápido; libera CPU |
| 10 | Kardex (relación `createdBy`) y balances paginados | backend-nest (ya en PR #14) | kardex en cero |
| 11 | Atajos: aceptar `LogicalKeyboardKey.add` y `numpadAdd`/`numpadSubtract` | flutter-dev | Ctrl++ en teclado español |
| 12 | Sincronización: procesar los lotes grandes fuera del hilo principal (`compute`/isolate) | flutter-dev | pausas de 1–8 s al facturar |
| 13 | Animaciones sin fin (botón "+" con brillo, indicadores) solo mientras hacen falta | flutter-dev / diseno-ui | CPU todo el día |
| 14 | Lista de facturas: no traer el detalle completo de cada factura (425 KB por página) ni `COUNT(DISTINCT)` con JOIN | backend-nest / dba | 0,4–0,8 s por página |
| 15 | Reducir `console.log` por operación en el servidor | backend-nest | 111 MB de log por hora de carga |

---

## 8. Qué NO se probó (y un incidente de la prueba)
- **Incidente — preferencias compartidas con la app real del Mac:** la prueba aísla HOME y el llavero, pero las
  preferencias de macOS (`NSUserDefaults`) ignoran el HOME aislado. Las corridas 1–3 escribieron en
  `~/Library/Preferences/com.example.baudexDesktop.plist` (el mismo de la app instalada en este Mac): 12 marcas de
  sincronización del negocio de prueba y la clave `flutter.full_sync_business_v1` (negocio de los datos locales), que quedó
  con el negocio de prueba. **Se borraron esas 13 claves** (`defaults delete`); las demás (correo, negocio, usuario
  recordados) no se tocaron. Valor anterior de `full_sync_business_v1`: desconocido; sin la clave, la app toma el negocio
  desde su base local, que es lo correcto. Desde la corrida 4 la prueba usa prefijo propio (`qaestres.`). Ojo: la rama
  `fix/estres-escaner-navegacion` de flutter-dev también escribe ahí (archivo `com.example.baudexDesktop.feestres.plist`).
- **Incidente — llavero:** la primera corrida (antes del llavero en memoria) leyó la sesión guardada de la app real
  ("Token inválido" contra el servidor local). No se escribió ni borró nada en el llavero que se pudiera verificar
  (las entradas visibles son del 6–7 de noviembre), pero si la app instalada pide iniciar sesión otra vez, puede ser esto.
- **Producción, el equipo del cliente, Windows e impresora**: nada. La simulación en verde no es prueba en el equipo real.
- `pg_stat_statements` (requería reiniciar el contenedor compartido); se usó el log de lentas + `auto_explain`.
- Los datos de la base de Baudex de verdad: la base se armó desde cero con las migraciones y siembra propia.
- Escribir en el teclado de verdad: las teclas se inyectan por el mismo camino que el motor de macOS (KeyData + mensaje
  crudo + `updateEditingValue`/`performAction` de la caja), pero no pasan por el sistema operativo.
- Varias pestañas de factura a la vez con muchas líneas, y sin internet (modo offline) bajo carga.
- La corrida del cierre/congelamiento de órdenes de compra no se reprodujo: puede necesitar el flujo exacto de guardar
  borrador desde el formulario.

## 9. Cómo repetirlo (después de los arreglos)
Ver `tool/estres/README.md` en la rama `test/estres-qa`. Resumen en §10.

Lo deja todo listo la rama `test/estres-qa` (frontend) y la base `baudex_qa` (se queda en el contenedor `ecommerce`).
1. Servidor a medir (con los arreglos) en el 3101, sin `.env`: copiar `start-backend.sh` de la carpeta de trabajo
   (`env -i`, `DB_NAME=baudex_qa`, `DB_USERNAME=baudex_qa`, `PORT=3101`) apuntando al `dist/main.js` de la rama arreglada.
   El usuario de base `baudex_qa` es solo local (contraseña en ese script, no es un secreto de producción).
2. `update active_sessions set is_active=false` en `baudex_qa` (límite de 5 equipos).
3. App: en `wt-fe-qa` hacer `git merge` (o rebase) de la rama de flutter-dev, y
   `flutter build macos --profile -t tool/estres/stress_main.dart`.
4. `python3 tool/estres/prep_ids.py <salida>` (notas en borrador frescas) y correr:
   `QA_HOME=<salida>/home QA_BUSINESS="Tienda QA Estres 1fa9874b" QA_CN_IDS=$(cat <salida>/cn_ids) QA_PO_IDS=$(cat <salida>/po_ids) QA_SNAPS=<salida>/fotos QA_STEPS=login,descarga,reposo,conteo,pos_escanear,pos_reescanear,pos_atajos,pos_productos_ida_vuelta,nota_credito,orden_compra,nav_loop,conteo QA_NAV_N=100 tool/estres/run_stress.sh <salida>`
   y en paralelo `tool/estres/hold_inventory_lock.sh <salida>/marca.txt 3e7f24a1-7243-40f4-b716-e9a1ba2de6d8 40` para la nota "lenta".
5. Servidor: `QA_URL=http://127.0.0.1:3101/api python3 tool/estres/api_load.py 8 40`, `cn_confirm_timing.py 10`,
   `product_create_timing.py 30`; consultas lentas: `docker logs --since <inicio> ecommerce | python3 tool/estres/pg_slowlog.py 15 --planes --pids=<pids>`.
6. Comparar con las tablas de este informe (§4 y §5). Criterios de "arreglado": volver a la factura < 1 s siempre; 0 escaneos perdidos;
   0 "foco perdido"; Ctrl+"+" funciona; nota lenta → aviso claro y sin "otra nota"; doble confirmación → 1 movimiento;
   tablero < 1 s y < 50 MB por petición; `GetPageRoute` vivos ≈ pantallas abiertas tras el bucle.

Archivos de esta noche (carpeta de trabajo, se borran al reiniciar el Mac):
`/private/tmp/claude-501/-Users-mac-Developer/b38c370a-6fb0-499a-b095-a769345b5011/scratchpad/baudex-qa/`
(`corrida1..4/` con resultados.json, memoria.jsonl, fotos y perfiles de CPU; `carga-*.md`, `lentas.md`, `run/backend-1-oom.log`).

---

## 10. Repetición con los arreglos (madrugada del 21, 05:10–06:50)

**Qué se corrió:** servidor `perf/consultas-y-nota-credito` @ b585ec5 (copia propia compilada, puerto 3101) sobre
`baudex_qa_d2` (copia nueva de `baudex_qa`); app `fix/estres-escaner-navegacion` @ af87240 con el mismo `stress_main`
(worktree `wt-fe-qa-despues`). App con `-NSAppSleepDisabled YES` (sin App Nap). Corridas **A** (todo, SIN sonda de
memoria), **C** (lector + ida y vuelta solo por ruta + Alt+6/Alt+2, sin sonda) y **B** (bucle de 90 vueltas CON sonda,
solo para la fuga). Preferencias con prefijo propio **nuevo en cada corrida** (con el prefijo repetido, una base Isar
nueva quedó con 0 productos y 0 facturas: el error §3.7 sigue, ver abajo).
Nota de método: en la versión arreglada el "volver" de la prueba usa `AppNav.back()` (lo que usan ahora las flechas de
la app); en la versión anterior usaba `Get.back()` (lo que usaban entonces).

### 10.1 Antes y después

| Qué | Antes (main) | Después (arreglos) | ¿Quedó? |
|---|---|---|---|
| 150 escaneos, catálogo completo | p95 176 ms, peor 407; 3 cuadros > 500 ms; foco perdido 9 | p95 109–112 ms, peor 112–143; **0** cuadros > 500 ms; foco perdido **0** | ✅ |
| 100 re-escaneos, catálogo completo | **43 perdidos**, p95 17,6 s, app sin responder 7,9 s | **0 perdidos**, p95 110–111 ms, mayor pausa 24–25 ms | ✅ |
| Foco de la caja del lector | se perdía cada ~15 escaneos | 0 pérdidas en 250 escaneos (A) y 250 (C) | ✅ |
| Ctrl + "+" teclado español / numérico, Ctrl + "-" numérico | no hacían nada | funcionan los 3 | ✅ |
| Volver de Productos a la factura con avisos en fila | p95 30 s, peor 42 s | 1,99 s p95 / 1,99 peor (incluye 0,4 s de espera de quietud de la prueba) → ≈1,6 s reales | ⚠️ mejora grande, **no llega a < 1 s** |
| Escanear al volver de Productos | p95 18 s, códigos pegados | p95 116 ms | ✅ |
| **Alt+6 (Productos) y Alt+2 (Facturar) con una venta a medias** | la venta se conserva (5 → 5 líneas) | **la venta se pierde (5 → 0 líneas)** — Alt+N ahora reemplaza la pila (`AppNav.openModule`) | ❌ **regresión** |
| Volver con aviso que aún no se mostró | — | `LateInitializationError` en `NavigationGuard.back` → `Get.closeAllSnackbars()` (navigation_guard.dart:113); el volver no ocurre. 3 veces en A, 4+ en B | ❌ **nuevo** |
| Nota crédito con el servidor ocupado 40 s | 30 s → "Error inesperado", queda en borrador; el servidor la confirma 11 s después | espera 39,5 s y queda **confirmada sin error**; 1 movimiento por línea (8/8 notas) | ✅ (la espera de 40 s sin aviso intermedio sigue siendo larga) |
| Nota siguiente muestra la anterior | 7 de 7 | 0 de 8 | ✅ |
| Doble confirmación simultánea (servidor) | stock y saldo dobles | 1 movimiento, acreditado = total | ✅ |
| Detalle de orden de compra apilado sobre otro | muestra la orden equivocada 6/6 | **sigue mostrando la equivocada 6/6** (controlador sin etiqueta) | ❌ |
| Tablero, 8 a la vez | servidor caído por memoria | p50 340 ms, RSS 77 → 83 MB, vivo | ✅ |
| Tablero, 16 a la vez | — (con 8 ya caía) | p50 246–309 ms, peor 458 ms, RSS pico 116 MB, vivo | ✅ |
| Cifras del tablero (hoy) | ventas 1.103.916.120 · costo 907.711.980 · utilidad 196.204.140 | idénticas | ✅ |
| Kardex vs stock vs lotes (20 productos, hasta 1.083 movimientos) | 400 siempre | **20/20 cuadran** (inicial + entradas − salidas = final = stock = lotes) | ✅ (pantalla no verificada con foto) |
| Crear producto (categoría de ~1.900) | 1.049 ms p50 | 27 ms p50 / 41 p95 | ✅ |
| Contraseña/códigos en respuestas | **9 endpoints** con `password` (hash bcrypt), `emailVerificationCode` y `passwordChanged` del usuario: facturas, detalle, notas, órdenes, caja actual, confirmar nota, `/users` (`passwordChanged`) y la respuesta guardada en `idempotency_keys` (3 filas viejas en la base la tienen) | **0** (11 endpoints + respuesta guardada con `Idempotency-Key`) | ✅ (las 3 filas viejas de `idempotency_keys` en las bases reales hay que limpiarlas) |
| Descarga inicial (equipo nuevo) | 72 s, 3 cuadros > 500 ms | 48 s, 0 cuadros > 500 ms, mayor pausa 36 ms | ✅ |
| 60 s quieto tras la descarga | peor cuadro 2,7 s, pausa 1,65 s | peor 335 ms, pausa 269 ms | ✅ |
| Base Isar nueva con marcas de sincronización viejas | 52 productos de 5.035 | **0 productos y 0 facturas** (corrida A con prefijo repetido) | ❌ sigue (§3.7) |
| Memoria tras 80–90 vueltas (corrida B, con sonda) | heap 39 → 61 MB (vuelta 0 → 80); `GetPageRoute` 405 vivas a la vuelta ~50 | heap **37 → 59,5 MB** (vuelta 0 → 80), 47 MB tras 60 s quieto; `AnimationController` 129 → 1.080; **`GetPageRoute` 567 vivas a la vuelta 50 y 935 a la ~85** con solo 1–2 pantallas abiertas | ❌ **la fuga sigue** |
| Errores durante 90 vueltas de navegación | 0 | **50** `LateInitializationError` (avisos, ver arriba); 1 vez la app terminó en `/login` | ❌ |
| Volver con 20 avisos en fila (5 intentos de "Volver" por vuelta) | **0 de 5** vueltas logró volver; 25 "volver sin efecto" | **5 de 5** al primer intento (el cambio de pantalla es inmediato; la pantalla queda quieta en 1,9–3,9 s) | ✅ |

Endpoints (8 a la vez, 40 peticiones, servidor en caliente):

| endpoint | antes p50/p95 ms | después p50/p95 ms |
|---|---|---|
| GET /products (lista 50) | 150/184 | 107/169 |
| GET /products?search= | 77/98 | 56/70 |
| GET /products/search | 55/68 | 42/54 |
| GET /products/barcode/:code | 38/46 | 59/107 |
| GET /products/:id | 25/30 | 34/48 |
| GET /customers (lista 50) | 24/29 | 27/30 |
| GET /customers/search | 18/21 | 20/25 |
| GET /invoices (lista 50) | 365/519 | 160/178 |
| GET /invoices?search= | 120/138 | 74/100 |
| GET /invoices/:id | 45/53 | 51/67 |
| GET /invoices/stats | 49/57 | 50/72 |
| GET kardex producto vendido | 27/31 (código 400) | 33/37 |
| GET /inventory/balances | 159/287 | 40/58 |
| GET /inventory/movements | 187/234 | 32/41 |
| GET /inventory/stats | 457/555 | 53/63 |
| GET /inventory/summary | 17/23 (código 400) | 19/23 (código 400) |
| GET /purchase-orders | 39/48 | 41/52 |
| GET /purchase-orders/:id | 26/31 | 27/32 |
| GET /credit-notes | 56/64 | 56/70 |
| GET /credit-notes/:id | 29/34 | 30/36 |
| GET /dashboard/summary hoy | 7168/7943 | 120/141 |
| GET /dashboard/summary mes | 7454/8049 | 109/125 |
| GET /sync/changes/products (desde 0) | 1134/1165 | 731/859 |
| GET /sync/changes/invoices (desde 0) | 1246/1411 | 1227/1395 |
| GET /sync/changes/inventory_movements | 166/235 | 197/381 |

El tablero "antes" se midió con 2 a la vez (con 8 se caía); "después" con 8.

**La fuga de rutas sigue (corrida B):** el camino de retención ya no pasa por `RouterReportManager._routesKey` (el
"conserje" lo limpia), pero las rutas siguen vivas por otro lado: `SyncService._lastSyncTime` → un `Obx` (indicador de
sincronización) → árbol vivo → `RawTooltipState._overlayController` → `OverlayPortalController._attachTarget` →
`WidgetStatesController._listeners` → pantallas cerradas. Un `WidgetStatesController` (o tooltip) que vive más que su
pantalla sigue guardando escuchas de botones de pantallas ya cerradas (`tool/estres/vm_retain.dart` lo muestra).

**Notas de las corridas:**
- Sin sonda y sin App Nap (corrida A) las pausas de 1–8 s desaparecieron también en lo que **no** se arregló (60 s quieto:
  peor cuadro 335 ms). Parte de las pausas "antes" venían de la sonda/App Nap, como dijo flutter-dev; los escaneos perdidos
  y la nota crédito no (se reprodujeron con datos de la base).
- El "volver" con avisos en la corrida C midió ~2 s porque el re-escaneo ya no muestra avisos; por eso se agregó la
  prueba explícita de 20 avisos (corridas antes D / después D).

### 10.2 Veredicto de la repetición: **aprobado con reservas — devuelto a flutter-dev por 4 puntos**
Quedó bien: lector (0 perdidos, foco, sin pausas), Ctrl++ español, volver con avisos, nota crédito (sin error falso,
sin nota equivocada, sin doble aplicación), tablero (16 a la vez, 120 ms, mismas cifras), kardex 20/20, crear producto
27 ms, sin contraseñas ni códigos en 11 respuestas, descarga 48 s sin trabas.
Sigue fallando:
1. **Regresión: Alt+6 → Alt+2 borra la venta en curso** (5 → 0 líneas; antes se conservaba). Foto `despuesC/fotos/007`.
2. **`AppNav.back` lanza `LateInitializationError`** al cerrar avisos que aún no se mostraron (`Get.closeAllSnackbars`,
   navigation_guard.dart:113) y entonces no vuelve: 3 veces en la corrida A, 50 en el bucle.
3. **Fuga de rutas sigue** (935 `GetPageRoute` vivas, heap +22 MB en 80 vueltas).
4. **Detalle de orden de compra apilado** sigue mostrando la orden equivocada (6/6).
5. (servidor/app, sin cambio) marcas de sincronización fuera de Isar → base nueva con 0 productos (§3.7); `/inventory/summary` 400;
   3 filas viejas en `idempotency_keys` con hash de contraseña que hay que borrar en las bases reales.

---

## 11. Verificación independiente de db14483 (21-nov, 07:40–08:52)

App `fix/estres-escaner-navegacion` @ **db14483** (worktree propio), servidor b585ec5 sobre `baudex_qa_d2`, app sin App Nap.
**Preferencias en un archivo propio** (`qa_prefs.json` dentro de la carpeta aislada, vía `SharedPreferencesStorePlatform`):
el plist real quedó idéntico (237 claves, mismo hash, sin modificar desde las 06:23).
Corridas: **v3A** (lector, atajos, Alt+N, avisos, nota crédito con servidor ocupado 40 s, sin sonda), **v3P** (órdenes
apiladas), **v3N** (base Isar borrada con marcas viejas en las preferencias), **v3B** (80 vueltas con sonda, para memoria).

| # | Qué se pidió confirmar | Resultado | |
|---|---|---|---|
| 1 | Alt+6 y luego Alt+2 conservan la venta | 5 líneas → **5 líneas** (af87240: 5 → 0) | ✅ |
| 2 | Volver sin `LateInitializationError`, con 20 avisos | 5 de 5 vueltas al primer intento; **0** `LateInitializationError` en toda la verificación (v3A, v3P y 80 vueltas de v3B; af87240: 50) | ✅ |
| 3 | Rutas vivas = pantallas abiertas en 80 vueltas | `GetPageRoute` vivas: **4** a la vuelta ~38 y **4** a la ~78, con 2 entradas en el navegador (af87240: 567 y 935). `AnimationController` 57–59 estable (antes subía a 1.080) | ✅ |
| 3b | ¿La lista de cuadros del arnés infla el heap ~9 MB a la vuelta 40? | **Sí, es cierto.** A la vuelta ~38 había **60.500 `FrameTiming`** guardados (≈152 B cada uno con su lista de 12 tiempos ≈ **9,2 MB**). Heap tras recolección: 46,4 MB → **37,2 MB descontándola**; a la vuelta ~78: 124.571 cuadros (≈18,9 MB), 55,5 MB → **36,6 MB**. Al terminar el bucle (lista vaciada) el heap volvió a **38,2 MB**. Sin la lista, la memoria es estable (≈37 MB). El arnés ahora acepta `QA_NO_FRAMES=1` | ✅ |
| 4 | Detalle de orden de compra apilado muestra la orden correcta | 4 de 4 pares A/B: A correcta, A tras ir a Productos y volver correcta, B encima correcta, al volver A correcta (af87240: equivocada 6/6) | ✅ |
| 5 | Base local nueva con marcas viejas descarga todo | Isar borrada, 12 marcas viejas en las preferencias: "el equipo no tiene registros pero había marca — se descarga todo" → **5.095 productos, 2.031 clientes, 19.681 facturas** en 58 s (af87240: 0 productos y 0 facturas) | ✅ |
| 6a | Escáner | 150 escaneos: 0 perdidos, p95 111 ms, peor 132 ms; 100 re-escaneos: 0 perdidos, p95 111 ms; 0 cuadros > 500 ms. Foco perdido **1 vez** (línea 2, justo después de limpiar la venta), luego 0 | ✅ (detalle menor) |
| 6b | Nota crédito con servidor ocupado 40 s | 1.ª nota: 38,6 s, confirmada sin error; las 6 confirmadas una sola vez (movimientos = líneas), ninguna muestra otra nota | ✅ |
| 6c | Ctrl++ teclado español / numérico, Ctrl+- numérico | funcionan los 3; 180/180 atajos | ✅ |
| 6d | Tablero | 8 y 16 a la vez: p50 199–229 ms, peor 348 ms, RSS pico 118 MB, servidor vivo. Kardex 20/20 cuadra. 0 respuestas con contraseña o códigos | ✅ |

**Detalles que quedan (no bloquean):** la lista y el detalle de órdenes de compra y el tablero siguen pintando cuadros
sin parar (animación continua: 80/80 y 40/40 veces sin quedar quietos); 8 cuadros > 500 ms en las 80 vueltas con la
sonda activa (la sonda fuerza recolección cada 60 s); 1 pérdida de foco al empezar una venta nueva. Pendiente aparte:
`/inventory/summary` 400 y limpiar las 3 filas viejas de `idempotency_keys` en las bases reales.

**Veredicto de db14483: aprobado** (los 6 puntos confirmados; sin regresiones en lo que ya pasaba).
Qué NO se probó: Windows, impresora, el equipo del cliente, producción y teclado físico real (las teclas se inyectan por
el camino del motor de macOS).
