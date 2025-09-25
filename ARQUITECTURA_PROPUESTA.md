# 🏗️ PROPUESTA DE ARQUITECTURA ESCALABLE - BAUDEX INVENTORY

## 📋 PROBLEMAS IDENTIFICADOS

### 1. **ARQUITECTURA DE INVENTARIO DEFICIENTE**
- Products tienen stock directo (incorrecto para multi-almacén)
- InventoryBalance con warehouseId opcional
- No hay relación fuerte entre Product-Warehouse-Stock

### 2. **FALTA DE DATOS INICIALES**
- Nuevos tenants no tienen almacenes por defecto
- Productos sin inventario inicial por almacén
- No hay proceso de onboarding

### 3. **PROBLEMAS DE ESCALABILIDAD**
- Stock global vs stock por almacén
- Movimientos de inventario no están bien trazados
- Falta de auditoría de cambios

---

## 🎯 SOLUCIÓN PROPUESTA

### **NUEVA ESTRUCTURA DE ENTIDADES**

#### 1. **Product Entity (Revisado)**
```dart
class Product extends Equatable {
  final String id;
  final String name;
  final String sku;
  final ProductType type;
  final ProductStatus status;
  // ❌ REMOVER: final double stock;
  // ❌ REMOVER: final double minStock;
  
  // ✅ AGREGAR: Configuración por almacén
  final double defaultMinStock; // Stock mínimo por defecto para nuevos almacenes
  final String defaultWarehouseId; // Almacén principal
}
```

#### 2. **Nueva Entidad: ProductWarehouseStock** 
```dart
class ProductWarehouseStock extends Equatable {
  final String productId;
  final String warehouseId;
  final double currentStock;
  final double minStock;
  final double reservedStock;
  final double averageCost;
  final DateTime lastUpdated;
  final String lastUpdatedBy;
  
  // Computed properties
  bool get isLowStock => currentStock <= minStock;
  bool get isOutOfStock => currentStock <= 0;
  double get availableStock => currentStock - reservedStock;
}
```

#### 3. **Nueva Entidad: StockMovement**
```dart
class StockMovement extends Equatable {
  final String id;
  final String productId;
  final String warehouseId;
  final MovementType type; // IN, OUT, TRANSFER, ADJUSTMENT
  final double quantity;
  final double unitCost;
  final double stockBefore;
  final double stockAfter;
  final String referenceId; // Invoice, PurchaseOrder, etc.
  final String reason;
  final String createdBy;
  final DateTime createdAt;
}
```

#### 4. **Warehouse Entity (Mejorado)**
```dart
class Warehouse extends Equatable {
  final String id;
  final String name;
  final String code;
  final bool isActive;
  final bool isDefault; // ✅ NUEVO: Marcar almacén principal
  final WarehouseType type; // MAIN, SECONDARY, VIRTUAL
  final String organizationId; // ✅ EXPLÍCITO
}
```

---

## 🚀 PLAN DE IMPLEMENTACIÓN

### **FASE 1: BACKEND CHANGES (PRIORIDAD ALTA)**

#### 1.1 **Database Migration**
```sql
-- Nueva tabla: product_warehouse_stock
CREATE TABLE product_warehouse_stock (
  product_id UUID REFERENCES products(id),
  warehouse_id UUID REFERENCES warehouses(id),
  current_stock DECIMAL DEFAULT 0,
  min_stock DECIMAL DEFAULT 0,
  reserved_stock DECIMAL DEFAULT 0,
  average_cost DECIMAL DEFAULT 0,
  last_updated TIMESTAMP DEFAULT NOW(),
  last_updated_by UUID REFERENCES users(id),
  PRIMARY KEY (product_id, warehouse_id)
);

-- Nueva tabla: stock_movements
CREATE TABLE stock_movements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES products(id),
  warehouse_id UUID REFERENCES warehouses(id),
  movement_type VARCHAR(20) NOT NULL,
  quantity DECIMAL NOT NULL,
  unit_cost DECIMAL,
  stock_before DECIMAL,
  stock_after DECIMAL,
  reference_type VARCHAR(50),
  reference_id UUID,
  reason TEXT,
  metadata JSONB,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Actualizar warehouses
ALTER TABLE warehouses ADD COLUMN is_default BOOLEAN DEFAULT FALSE;
ALTER TABLE warehouses ADD COLUMN warehouse_type VARCHAR(20) DEFAULT 'SECONDARY';
```

#### 1.2 **Tenant Onboarding Service**
```typescript
class TenantOnboardingService {
  async setupDefaultWarehouse(organizationId: string) {
    // 1. Crear almacén principal
    const defaultWarehouse = await this.warehouseRepository.create({
      name: 'Almacén Principal',
      code: 'ALM-001',
      isDefault: true,
      isActive: true,
      type: 'MAIN',
      organizationId
    });

    // 2. Crear stock inicial para productos existentes
    const products = await this.productRepository.findByOrganization(organizationId);
    for (const product of products) {
      await this.createInitialStock(product.id, defaultWarehouse.id);
    }

    return defaultWarehouse;
  }

  private async createInitialStock(productId: string, warehouseId: string) {
    await this.stockRepository.create({
      productId,
      warehouseId,
      currentStock: 0,
      minStock: 10, // Default
      reservedStock: 0,
      averageCost: 0
    });
  }
}
```

### **FASE 2: FRONTEND CHANGES**

#### 2.1 **Nuevas Entidades Frontend**
- ProductWarehouseStock entity
- StockMovement entity  
- Warehouse entity mejorado

#### 2.2 **Nuevos Controladores**
```dart
class StockController extends GetxController {
  // Gestión de stock por almacén
  Future<List<ProductWarehouseStock>> getStockByWarehouse(String warehouseId);
  Future<void> transferStock(StockTransferRequest request);
  Future<void> adjustStock(StockAdjustmentRequest request);
}
```

#### 2.3 **Flujo de Onboarding**
```dart
class OnboardingController extends GetxController {
  Future<void> setupInitialWarehouse() {
    // Crear almacén principal automáticamente
    // Navegar a configuración de productos
    // Mostrar tutorial
  }
}
```

---

## 🎯 BENEFICIOS DE LA SOLUCIÓN

### **1. ESCALABILIDAD**
- ✅ Stock por almacén (multi-warehouse)
- ✅ Trazabilidad completa de movimientos
- ✅ Auditoría automática

### **2. ARQUITECTURA LIMPIA**
- ✅ Separación clara de responsabilidades
- ✅ Entidades bien definidas
- ✅ Relaciones explícitas

### **3. EXPERIENCIA DE USUARIO**
- ✅ Onboarding automático
- ✅ Configuración inicial simplificada
- ✅ Datos coherentes desde el inicio

### **4. MANTENIBILIDAD**
- ✅ Código más limpio
- ✅ Testing más fácil
- ✅ Menos bugs relacionados con stock

---

## 📈 MÉTRICAS DE ÉXITO

### **Antes (Actual)**
- ❌ Stock global incorrecto
- ❌ Nuevos tenants sin almacenes
- ❌ Inventario inconsistente

### **Después (Propuesto)**
- ✅ Stock preciso por almacén
- ✅ Onboarding automático
- ✅ Inventario confiable
- ✅ Escalabilidad para 1000+ almacenes

---

## ⚠️ RIESGOS Y MITIGACIÓN

### **Riesgos**
1. **Migración de datos existentes**
2. **Tiempo de desarrollo**
3. **Testing exhaustivo requerido**

### **Mitigación**
1. **Script de migración gradual**
2. **Implementación por fases**
3. **Suite de tests automatizados**

---

## 🔄 CRONOGRAMA SUGERIDO

### **Semana 1-2: Backend Foundation**
- Database migrations
- New entities y repositories
- Tenant onboarding service

### **Semana 3-4: Frontend Adaptation**
- New entities frontend
- Updated controllers
- UI modifications

### **Semana 5: Integration & Testing**
- End-to-end testing
- Data migration
- Performance testing

### **Semana 6: Deployment**
- Staging deployment
- Production migration
- Monitoring setup

---

Este plan convierte Baudex en un sistema de inventario robusto, escalable y listo para empresas con múltiples almacenes y operaciones complejas.