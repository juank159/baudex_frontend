# Plan de Implementación: Sistema de Consumo de Saldo a Favor

## Resumen Ejecutivo

Implementar un sistema integral que permita a los clientes utilizar su saldo a favor de manera inteligente y automática en todo el ciclo de ventas (facturas y créditos), con trazabilidad completa y soporte para pagos combinados.

---

## Alcance del Proyecto

### Funcionalidades a Implementar

| Módulo | Funcionalidad | Comportamiento |
|--------|---------------|----------------|
| **Facturas** | Detectar saldo al procesar venta | Preguntar si desea usar saldo (total/parcial) |
| **Facturas** | Pagos combinados | Saldo + otro método de pago |
| **Créditos** | Detectar saldo al seleccionar cliente | Aplicar automáticamente |
| **Créditos** | Trazabilidad | Registrar en historial de movimientos |
| **General** | Pagos combinados | Permitir múltiples métodos de pago |

---

## Arquitectura de la Solución

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTE                                   │
│                    (tiene saldo a favor)                         │
└─────────────────────────────────────────────────────────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            ▼                                   ▼
┌─────────────────────┐               ┌─────────────────────┐
│      FACTURAS       │               │      CRÉDITOS       │
│  (pregunta al user) │               │ (aplica automático) │
└─────────────────────┘               └─────────────────────┘
            │                                   │
            ▼                                   ▼
┌─────────────────────┐               ┌─────────────────────┐
│ ¿Usar saldo a favor?│               │ Saldo detectado:    │
│ □ Sí, usar todo     │               │ Se aplicará $X      │
│ □ Sí, usar parte    │               │ automáticamente     │
│ □ No, pagar normal  │               └─────────────────────┘
└─────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PAGO COMBINADO                                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │Saldo: $30K  │ +│Efectivo:$20K│ =│ Total: $50K │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     TRAZABILIDAD                                 │
│  - Historial de crédito: "Pago con saldo a favor"               │
│  - Historial de saldo: "Usado en crédito/factura #XXX"          │
│  - Factura: Registro del pago parcial/total                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Fases de Implementación

### FASE 1: Backend - Integración de Saldo con Facturas
**Prioridad:** Alta | **Estimación:** Backend

#### 1.1 Crear endpoint para aplicar saldo a facturas
```typescript
// POST /invoices/:id/apply-balance
// Body: { amount?: number } // Si no se envía, aplica todo el saldo disponible
```

#### 1.2 Modificar InvoicesService
- Agregar método `applyClientBalance(invoiceId, amount?, createdById)`
- Validar que la factura no esté pagada
- Validar saldo disponible del cliente
- Crear registro de pago con método "saldo_favor"
- Registrar transacción en historial de saldo del cliente
- Actualizar balance de la factura

#### 1.3 Agregar método de pago "saldo_favor"
- En el enum de métodos de pago de facturas

#### Archivos a modificar:
- `backend/src/invoices/invoices.service.ts`
- `backend/src/invoices/invoices.controller.ts`
- `backend/src/invoices/entities/payment.entity.ts` (si aplica)

---

### FASE 2: Backend - Mejoras en Créditos
**Prioridad:** Alta | **Estimación:** Backend

#### 2.1 Mejorar endpoint de crear crédito
- Al crear un crédito, verificar si el cliente tiene saldo a favor
- Si tiene, aplicarlo automáticamente
- Registrar en el historial del crédito (BALANCE_USED)
- Registrar en el historial del saldo (USAGE)

#### 2.2 Endpoint para verificar saldo del cliente
```typescript
// GET /client-balance/customer/:customerId/available
// Response: { hasBalance: boolean, amount: number }
```

#### Archivos a modificar:
- `backend/src/customer-credits/customer-credits.service.ts`
- `backend/src/customer-credits/client-balance.service.ts`

---

### FASE 3: Frontend - Facturas con Saldo a Favor
**Prioridad:** Alta | **Estimación:** Frontend

#### 3.1 Modificar flujo de creación de factura
- Al seleccionar cliente, verificar si tiene saldo a favor
- Mostrar banner/notificación: "💰 Este cliente tiene $X de saldo a favor"

#### 3.2 Dialog de confirmación al procesar venta
```dart
// Cuando el cliente tiene saldo y procesa la factura:
// Mostrar dialog:
// "El cliente tiene $50,000 de saldo a favor"
//
// Opciones:
// ○ Usar todo el saldo ($50,000)
// ○ Usar una parte: [_____]
// ○ No usar saldo (pagar normal)
//
// [Cancelar] [Continuar]
```

#### 3.3 Soporte para pagos combinados
- Si el saldo no cubre el total, permitir agregar otro método de pago
- Mostrar desglose: Saldo: $30,000 + Efectivo: $20,000 = Total: $50,000

#### Archivos a modificar:
- `frontend/lib/features/invoices/presentation/pages/create_invoice_page.dart`
- `frontend/lib/features/invoices/presentation/widgets/` (crear dialogs)
- `frontend/lib/features/invoices/data/datasources/invoice_remote_datasource.dart`

---

### FASE 4: Frontend - Créditos con Saldo Automático
**Prioridad:** Alta | **Estimación:** Frontend

#### 4.1 Modificar dialog/página de crear crédito
- Al seleccionar cliente, cargar su saldo a favor
- Mostrar banner informativo: "💰 Saldo a favor: $X - Se aplicará automáticamente"
- El monto del crédito se reducirá por el saldo disponible

#### 4.2 Mostrar preview del resultado
```
┌────────────────────────────────────────┐
│ Monto del crédito:        $100,000     │
│ (-) Saldo a favor:        - $30,000    │
│ ─────────────────────────────────────  │
│ Deuda inicial:            $70,000      │
└────────────────────────────────────────┘
```

#### 4.3 Registrar en historial
- Al crear el crédito, el backend aplica automáticamente el saldo
- Frontend muestra confirmación con desglose

#### Archivos a modificar:
- `frontend/lib/features/customer_credits/presentation/widgets/create_credit_dialog.dart`
- `frontend/lib/features/customer_credits/presentation/controllers/customer_credit_controller.dart`

---

### FASE 5: Frontend - Mejoras en Dialog de Pago de Créditos
**Prioridad:** Media | **Estimación:** Frontend

#### 5.1 Mostrar saldo disponible
- Al abrir AddCreditPaymentDialog, cargar saldo del cliente
- Mostrar banner si tiene saldo: "💰 Saldo disponible: $X"

#### 5.2 Agregar "Saldo a Favor" como método de pago
- En el dropdown de métodos de pago, agregar "Saldo a Favor"
- Al seleccionar, mostrar campo para monto (default: min(saldo, deuda))

#### 5.3 Pagos combinados
- Permitir: Saldo + otro método
- Ejemplo: $20,000 saldo + $30,000 efectivo

#### Archivos a modificar:
- `frontend/lib/features/customer_credits/presentation/widgets/add_credit_payment_dialog.dart`

---

### FASE 6: Trazabilidad y Reportes
**Prioridad:** Media | **Estimación:** Backend + Frontend

#### 6.1 Mejorar historial de transacciones
- En créditos: Mostrar "Pago con saldo a favor" con icono distintivo
- En saldo: Mostrar "Usado en factura #XXX" o "Usado en crédito #XXX"

#### 6.2 Relaciones claras
- Cada transacción de saldo debe tener `relatedCreditId` o `relatedInvoiceId`
- Permitir navegación: Click en transacción → Ver crédito/factura relacionada

#### Archivos a modificar:
- `backend/src/customer-credits/entities/client-balance-transaction.entity.ts` (agregar relatedInvoiceId)
- `frontend/lib/features/customer_credits/presentation/widgets/client_balance_dialogs.dart`

---

## Modelo de Datos

### Modificaciones Requeridas

#### 1. ClientBalanceTransaction (agregar relación con factura)
```typescript
// Agregar campo:
@Column({ type: 'uuid', name: 'related_invoice_id', nullable: true })
relatedInvoiceId?: string;

@ManyToOne(() => Invoice, { nullable: true, onDelete: 'SET NULL' })
@JoinColumn({ name: 'related_invoice_id' })
relatedInvoice?: Invoice;
```

#### 2. PaymentMethod en Facturas (agregar saldo_favor)
```typescript
export enum PaymentMethod {
  CASH = 'cash',
  CARD = 'card',
  TRANSFER = 'transfer',
  // ... otros
  CLIENT_BALANCE = 'client_balance', // NUEVO
}
```

---

## Flujos de Usuario

### Flujo 1: Crear Factura con Saldo a Favor

```
1. Usuario crea factura
2. Selecciona cliente "Juan Pérez"
3. Sistema detecta: Juan tiene $50,000 de saldo
4. Muestra banner: "💰 Este cliente tiene $50,000 de saldo a favor"
5. Usuario agrega productos (Total: $80,000)
6. Usuario da click en "Procesar Venta"
7. Sistema muestra dialog:
   ┌─────────────────────────────────────────────┐
   │  💰 Usar Saldo a Favor                      │
   │                                             │
   │  El cliente tiene $50,000 disponibles       │
   │  Total de la factura: $80,000               │
   │                                             │
   │  ○ Usar todo el saldo ($50,000)             │
   │    Restante a pagar: $30,000                │
   │                                             │
   │  ○ Usar una parte: [_30,000_]               │
   │    Restante a pagar: $50,000                │
   │                                             │
   │  ○ No usar saldo                            │
   │    Pagar todo: $80,000                      │
   │                                             │
   │  [Cancelar]              [Continuar]        │
   └─────────────────────────────────────────────┘
8. Si usa saldo parcial/total:
   - Se descuenta del saldo del cliente
   - Se registra pago con método "saldo_favor"
   - Si queda restante, mostrar dialog de método de pago
9. Factura creada con desglose de pagos
```

### Flujo 2: Crear Crédito con Saldo a Favor (Automático)

```
1. Usuario abre dialog de crear crédito
2. Selecciona cliente "María López"
3. Sistema detecta: María tiene $20,000 de saldo
4. Muestra banner:
   "💰 Saldo a favor: $20,000 - Se aplicará automáticamente"
5. Usuario ingresa monto del crédito: $100,000
6. Sistema muestra preview:
   ┌─────────────────────────────────────────────┐
   │  📊 Resumen del Crédito                     │
   │                                             │
   │  Monto del crédito:      $100,000           │
   │  (-) Saldo a favor:      - $20,000          │
   │  ─────────────────────────────────────────  │
   │  Deuda inicial:          $80,000            │
   │                                             │
   │  ✓ El saldo se aplicará automáticamente    │
   └─────────────────────────────────────────────┘
7. Usuario confirma
8. Sistema:
   - Crea crédito con deuda inicial de $80,000
   - Registra transacción BALANCE_USED en crédito
   - Registra transacción USAGE en saldo del cliente
   - Descuenta saldo del cliente
```

### Flujo 3: Pago Combinado en Crédito Existente

```
1. Usuario abre crédito de "Pedro García" (Pendiente: $50,000)
2. Click en "Agregar Pago"
3. Sistema detecta: Pedro tiene $15,000 de saldo
4. Muestra en dialog:
   ┌─────────────────────────────────────────────┐
   │  Agregar Pago                               │
   │                                             │
   │  💰 Saldo disponible: $15,000               │
   │                                             │
   │  Método de pago: [Saldo a Favor    ▼]       │
   │  Monto: [$15,000_____]                      │
   │                                             │
   │  [+ Agregar otro método de pago]            │
   │                                             │
   │  ─────────────────────────────────────────  │
   │  Método: [Efectivo         ▼]               │
   │  Monto: [$20,000_____]                      │
   │                                             │
   │  ─────────────────────────────────────────  │
   │  Resumen:                                   │
   │  • Saldo a favor:  $15,000                  │
   │  • Efectivo:       $20,000                  │
   │  • Total abono:    $35,000                  │
   │                                             │
   │  [Cancelar]              [Registrar]        │
   └─────────────────────────────────────────────┘
5. Sistema registra ambos pagos
6. Historial muestra ambos movimientos
```

---

## Orden de Implementación

| # | Fase | Descripción | Dependencias |
|---|------|-------------|--------------|
| 1 | FASE 2.2 | Endpoint verificar saldo | - |
| 2 | FASE 1 | Backend facturas + saldo | Fase 2.2 |
| 3 | FASE 2.1 | Backend créditos auto-aplicar | Fase 2.2 |
| 4 | FASE 4 | Frontend créditos auto-aplicar | Fase 2.1 |
| 5 | FASE 3 | Frontend facturas + saldo | Fase 1 |
| 6 | FASE 5 | Frontend pagos combinados créditos | Fase 2.2 |
| 7 | FASE 6 | Trazabilidad mejorada | Todas |

---

## Checklist de Implementación

### Backend
- [ ] Agregar `relatedInvoiceId` a `ClientBalanceTransaction`
- [ ] Crear migración para nuevo campo
- [ ] Agregar `client_balance` a enum de métodos de pago en facturas
- [ ] Crear `InvoicesService.applyClientBalance()`
- [ ] Crear endpoint `POST /invoices/:id/apply-balance`
- [ ] Modificar `CustomerCreditsService.create()` para auto-aplicar saldo
- [ ] Crear endpoint `GET /client-balance/customer/:id/available`

### Frontend
- [ ] Crear `UseBalanceDialog` para facturas
- [ ] Modificar `CreateInvoicePage` para detectar saldo
- [ ] Modificar `CreateCreditDialog` para mostrar y aplicar saldo
- [ ] Modificar `AddCreditPaymentDialog` para pagos combinados
- [ ] Agregar "Saldo a Favor" como método de pago
- [ ] Mejorar visualización de historial de transacciones

### Testing
- [ ] Test: Crear factura usando saldo total
- [ ] Test: Crear factura usando saldo parcial
- [ ] Test: Crear factura con pago combinado (saldo + efectivo)
- [ ] Test: Crear crédito con auto-aplicación de saldo
- [ ] Test: Pago de crédito con saldo a favor
- [ ] Test: Pago combinado en crédito existente
- [ ] Test: Trazabilidad correcta en ambos historiales

---

## Notas Importantes

1. **Concurrencia**: Usar transacciones para evitar race conditions al usar saldo
2. **Validaciones**: Siempre verificar saldo disponible antes de usarlo
3. **Rollback**: Si falla la creación de factura/crédito, revertir el uso del saldo
4. **Auditoría**: Todas las operaciones deben quedar registradas con usuario y timestamp
5. **Permisos**: Verificar que el usuario tenga permisos para usar saldo del cliente
