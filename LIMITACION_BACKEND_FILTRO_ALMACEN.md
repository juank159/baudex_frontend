# ⚠️ LIMITACIÓN DEL BACKEND: Filtro por Almacén en Movimientos

## 🚨 PROBLEMA IDENTIFICADO

El backend **NO soporta filtrar movimientos de inventario por almacén**.

### ❌ Error del Backend:
```
Error: property warehouse_id should not exist
URL: /api/inventory/movements?warehouse_id=...
```

### 🔍 Análisis Técnico:
- El DTO de `/api/inventory/movements` **no incluye ningún parámetro de almacén**
- Se probaron: `warehouseId`, `warehouse_id` - ambos rechazados
- Es una **limitación del backend**, no del frontend

## ✅ SOLUCIÓN TEMPORAL IMPLEMENTADA

### **Cambios Realizados:**
1. **Comentado filtro en controller** (línea 217-218)
2. **Comentado filtro en datasource** (línea 164-165)  
3. **Agregado mensaje informativo** al usuario

### **Comportamiento Actual:**
- ✅ Pantalla funciona sin errores
- ✅ Muestra **todos** los movimientos (sin filtrar)
- ✅ Mensaje explicativo: "Mostrando todos los movimientos. El filtro por [Almacén] no está disponible aún."

## 🛠️ SOLUCIÓN PERMANENTE REQUERIDA

### **En el Backend se necesita:**

1. **Actualizar el DTO:**
```typescript
// Archivo: src/inventory/dto/get-inventory-movements.dto.ts
export class GetInventoryMovementsDto {
  @IsOptional()
  @IsString()
  warehouseId?: string;
  
  // ... otros campos existentes
}
```

2. **Actualizar el Service:**
```typescript
// Agregar filtro por almacén en la query
findMovements(params) {
  const query = this.movementsRepository.createQueryBuilder();
  
  if (params.warehouseId) {
    query.andWhere('movement.warehouseId = :warehouseId', { 
      warehouseId: params.warehouseId 
    });
  }
  
  return query.getMany();
}
```

## 📋 ESTADO ACTUAL

### **✅ Funciona:**
- Navegación a movimientos desde detalle de almacén
- Pantalla de movimientos carga correctamente
- Muestra todos los movimientos

### **⚠️ Limitación:**
- **NO filtra por almacén específico**
- Muestra movimientos de **todos** los almacenes
- Mensaje informativo al usuario sobre la limitación

## 🔄 PASOS SIGUIENTES

1. **Inmediato:** Funcionalidad operativa con limitación conocida
2. **Corto plazo:** Implementar filtro en backend  
3. **Después:** Descomentar líneas 217-218 en controller y 164-165 en datasource

---

**Nota:** La funcionalidad "Ver Inventario" puede tener el mismo problema - verificar por separado.