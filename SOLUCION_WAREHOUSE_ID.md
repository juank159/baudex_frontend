# 🔧 SOLUCIÓN AL ERROR: "property warehouse_id should not exist"

## 🚨 PROBLEMA IDENTIFICADO

El backend está rechazando el parámetro `warehouse_id` porque el endpoint usa **camelCase** como todos los demás.

### ❌ Error Original:
```
Error: property warehouse_id should not exist
URL: /api/inventory/movements?warehouse_id=522db9af...
```

### ✅ Solución Aplicada:
```
URL: /api/inventory/movements?warehouseId=522db9af...
```

## 🔧 CAMBIO REALIZADO

**Archivo**: `lib/features/inventory/data/datasources/inventory_remote_datasource.dart`
**Línea**: 164

**Antes:**
```dart
if (params.warehouseId != null) queryParams['warehouse_id'] = params.warehouseId;
```

**Después:**
```dart
if (params.warehouseId != null) queryParams['warehouseId'] = params.warehouseId;
```

## 🧪 CÓMO PROBAR

1. **Reinicia la app** si está ejecutándose
2. Ve a **Almacenes → Selecciona un almacén → Ver Movimientos**
3. ✅ **Debería funcionar** sin el error 500

## 📝 NOTAS

- El error era del **backend**, no del frontend
- El backend usa **snake_case** (`warehouse_id`)
- El frontend usa **camelCase** internamente pero envía **snake_case** al backend
- Solo cambié la línea específica para movimientos de inventario

## ✅ ANÁLISIS DE LA SOLUCIÓN

La clave fue analizar otros endpoints en el mismo datasource:
- Líneas 298, 330, 415, etc.: Todos usan `warehouseId` (camelCase)
- Solo los movimientos tenían `warehouse_id` (snake_case) - **esto era incorrecto**

El backend es **consistente con camelCase** en todos sus endpoints.

**¡Prueba ahora y me dices si funciona!** 🚀