#!/bin/bash
# Simula un servidor ocupado: cuando la app entra al escenario de notas
# crédito, toma el candado de inventario del negocio por N segundos (lo mismo
# que hace una venta o una creación de producto larga). Así se reproduce
# "confirmar tarda, muestra error y luego aparece confirmada".
# Uso: hold_inventory_lock.sh <archivo_marca> <organization_id> [segundos=40]
MARK="$1"; ORG="$2"; SECS="${3:-40}"
PSQL=${QA_PSQL:-"docker exec -i ecommerce psql -U baudex_qa -d baudex_qa -X"}
until grep -q "nota_credito_confirmar" "$MARK" 2>/dev/null; do sleep 0.5; done
echo "$(date +%T) tomo el candado de inventario $SECS s"
$PSQL -c "begin; select pg_advisory_xact_lock(hashtext('movement_number_$ORG')); select pg_sleep($SECS); commit;" > /dev/null
echo "$(date +%T) suelto el candado"
