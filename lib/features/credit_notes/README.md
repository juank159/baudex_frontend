# Credit Notes Feature

Feature completo de Notas de Crédito implementado siguiendo Clean Architecture y las especificaciones del proyecto Baudex.

## Estructura del Feature

```
credit_notes/
├── domain/                          # Capa de Dominio (Lógica de Negocio)
│   ├── entities/
│   │   ├── credit_note.dart         # Entidad principal con enums (Type, Reason, Status)
│   │   └── credit_note_item.dart    # Items de la nota de crédito
│   ├── repositories/
│   │   └── credit_note_repository.dart  # Interface del repositorio
│   └── usecases/                    # 11 Casos de uso
│       ├── create_credit_note.dart
│       ├── get_credit_note_by_id.dart
│       ├── get_credit_notes.dart
│       ├── get_credit_notes_by_invoice.dart
│       ├── get_remaining_creditable_amount.dart
│       ├── update_credit_note.dart
│       ├── confirm_credit_note.dart
│       ├── cancel_credit_note.dart
│       ├── delete_credit_note.dart
│       ├── download_credit_note_pdf.dart
│       └── sync_credit_notes.dart
│
├── data/                            # Capa de Datos
│   ├── models/
│   │   ├── credit_note_model.dart   # Extiende CreditNote con JSON
│   │   └── credit_note_item_model.dart
│   ├── datasources/
│   │   └── credit_note_remote_datasource.dart  # Implementa todos los endpoints con DioClient
│   └── repositories/
│       └── credit_note_repository_impl.dart    # Implementación del repositorio
│
└── presentation/                    # Capa de Presentación
    ├── controllers/                 # GetX Controllers
    │   ├── credit_note_list_controller.dart     # Lista con filtros y paginación
    │   ├── credit_note_detail_controller.dart   # Detalle con acciones
    │   └── credit_note_form_controller.dart     # Formulario crear/editar
    ├── screens/
    │   ├── credit_note_list_screen.dart
    │   ├── credit_note_detail_screen.dart
    │   └── credit_note_form_screen.dart
    ├── widgets/
    │   └── invoice_credit_notes_widget.dart     # Widget reutilizable para facturas
    └── bindings/
        └── credit_note_binding.dart             # Dependency Injection
```

## Características Implementadas

### Domain Layer

**Entidades:**
- `CreditNote`: Entidad principal con todos los campos requeridos
- `CreditNoteItem`: Items de la nota de crédito con relación a productos e items de factura
- Enums:
  - `CreditNoteType`: full (completa), partial (parcial)
  - `CreditNoteReason`: productReturn, discount, error, cancellation, other
  - `CreditNoteStatus`: draft, confirmed, cancelled

**Repository Interface:**
- Define 11 métodos para todas las operaciones CRUD y especiales
- Usa parámetros tipados (CreateCreditNoteParams, UpdateCreditNoteParams, QueryCreditNotesParams)
- Retorna `Either<Failure, Success>` para manejo de errores

**Use Cases:**
- Un use case por cada operación del repositorio
- Separación clara de responsabilidades
- Fácil de testear

### Data Layer

**Models:**
- Extienden las entidades del dominio
- Implementan `toJson()` y `fromJson()` para serialización
- Request models separados para crear y actualizar

**Remote Datasource:**
- Implementa todos los endpoints del backend NestJS
- Usa `DioClient` correctamente
- Manejo robusto de errores con excepciones tipadas
- Endpoints implementados:
  - POST /credit-notes (crear)
  - GET /credit-notes/:id (obtener por ID)
  - GET /credit-notes (listar con filtros)
  - GET /credit-notes/invoice/:invoiceId (por factura)
  - PATCH /credit-notes/:id (actualizar)
  - POST /credit-notes/:id/confirm (confirmar)
  - POST /credit-notes/:id/cancel (cancelar)
  - DELETE /credit-notes/:id (eliminar)
  - GET /credit-notes/invoice/:invoiceId/remaining-creditable (monto restante)
  - GET /credit-notes/:id/pdf (descargar PDF)

**Repository Implementation:**
- Online-first (requiere conexión para todas las operaciones)
- Mapeo correcto de excepciones a Failures
- Validación de conectividad antes de operaciones

### Presentation Layer

**Controllers (GetX):**
- `CreditNoteListController`:
  - Paginación automática con scroll infinito
  - Búsqueda con debounce
  - Filtros por status, type, reason, fecha, etc.
  - Acciones rápidas (confirmar, cancelar, eliminar)

- `CreditNoteDetailController`:
  - Carga de detalle completo
  - Acciones contextuales según estado
  - Descarga de PDF
  - Navegación a factura y cliente relacionados

- `CreditNoteFormController`:
  - Modo creación y edición
  - Validación de formulario
  - Cálculo automático de totales
  - Gestión de items
  - Integración con facturas

**Screens:**
- `CreditNoteListScreen`: Lista con búsqueda, filtros, y acciones
- `CreditNoteDetailScreen`: Vista detallada con todas las relaciones
- `CreditNoteFormScreen`: Formulario completo para crear/editar

**Widgets:**
- `InvoiceCreditNotesWidget`: Widget reutilizable para mostrar notas de crédito en detalles de factura

**Bindings:**
- `CreditNoteBinding`: Registra todas las dependencias base
- `CreditNoteListBinding`: Específico para lista
- `CreditNoteDetailBinding`: Específico para detalle
- `CreditNoteFormBinding`: Específico para formulario

## Integración con el Proyecto

### 1. Registrar Rutas

En tu archivo de rutas (probablemente en `/lib/app/config/routes/`), agrega:

```dart
import 'package:baudex_desktop/features/credit_notes/presentation/bindings/credit_note_binding.dart';
import 'package:baudex_desktop/features/credit_notes/presentation/screens/credit_note_list_screen.dart';
import 'package:baudex_desktop/features/credit_notes/presentation/screens/credit_note_detail_screen.dart';
import 'package:baudex_desktop/features/credit_notes/presentation/screens/credit_note_form_screen.dart';

// En tu lista de GetPage:
GetPage(
  name: '/credit-notes',
  page: () => const CreditNoteListScreen(),
  binding: CreditNoteListBinding(),
),
GetPage(
  name: '/credit-notes/new',
  page: () => const CreditNoteFormScreen(),
  binding: CreditNoteFormBinding(),
),
GetPage(
  name: '/credit-notes/:id',
  page: () => const CreditNoteDetailScreen(),
  binding: CreditNoteDetailBinding(),
),
GetPage(
  name: '/credit-notes/:id/edit',
  page: () => const CreditNoteFormScreen(),
  binding: CreditNoteFormBinding(),
),
```

### 2. Registrar Dependencias Globales (Opcional)

Si quieres que las dependencias estén disponibles globalmente, registra `CreditNoteBinding` en tu `InitialBinding`:

```dart
@override
void dependencies() {
  // ... otras dependencias
  CreditNoteBinding().dependencies();
}
```

### 3. Usar el Widget en Facturas

En tu pantalla de detalle de factura, agrega:

```dart
import 'package:baudex_desktop/features/credit_notes/presentation/widgets/invoice_credit_notes_widget.dart';

// En tu build:
InvoiceCreditNotesWidget(invoiceId: invoice.id)
```

### 4. Agregar al Menú de Navegación

Agrega un item al menú principal:

```dart
ListTile(
  leading: const Icon(Icons.receipt_long),
  title: const Text('Notas de Crédito'),
  onTap: () => Get.toNamed('/credit-notes'),
)
```

## Endpoints del Backend

Asegúrate de que tu backend NestJS tenga implementados estos endpoints:

```
POST   /api/credit-notes
GET    /api/credit-notes/:id
GET    /api/credit-notes
PATCH  /api/credit-notes/:id
POST   /api/credit-notes/:id/confirm
POST   /api/credit-notes/:id/cancel
DELETE /api/credit-notes/:id
GET    /api/credit-notes/invoice/:invoiceId
GET    /api/credit-notes/invoice/:invoiceId/remaining-creditable
GET    /api/credit-notes/:id/pdf
```

## Notas Técnicas

### Patrón de Arquitectura
- **Clean Architecture**: Separación estricta en 3 capas (Domain, Data, Presentation)
- **Dependency Rule**: Las dependencias fluyen hacia adentro (Presentation → Data → Domain)
- **Entities vs Models**: Las entidades son puras (sin dependencias), los models manejan JSON

### Estado y Reactividad
- **GetX Observables**: Todos los estados reactivos usan `.obs`
- **Obx Widget**: Actualización automática de UI
- **GetX Controllers**: Solo manejan estado, NO lógica de negocio

### Manejo de Errores
- **Either Pattern**: Usa `dartz` para Either<Failure, Success>
- **Failures Tipados**: ServerFailure, ConnectionFailure, ValidationFailure, etc.
- **Excepciones en Data Layer**: Se convierten a Failures en Repository

### Networking
- **DioClient**: Cliente HTTP centralizado
- **Online-First**: Todas las operaciones requieren conexión
- **Error Handling**: Manejo correcto de DioException con códigos de estado

## Mejoras Futuras (Opcionales)

1. **Offline Support con ISAR**:
   - Agregar local datasource con ISAR
   - Implementar sincronización offline-first
   - Queue de operaciones pendientes

2. **Testing**:
   - Unit tests para use cases
   - Tests para repository implementation
   - Widget tests para screens

3. **Validaciones Avanzadas**:
   - Validación de monto máximo acreditable
   - Prevención de duplicados
   - Validación de items contra factura original

4. **Exportación**:
   - Exportar lista a Excel/CSV
   - Impresión térmica de notas de crédito
   - Email automático al cliente

5. **Analytics**:
   - Dashboard de notas de crédito
   - Reportes de créditos por período
   - Razones más comunes de créditos

## Recursos

- [GetX Documentation](https://pub.dev/packages/get)
- [Dartz Documentation](https://pub.dev/packages/dartz)
- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

## Autor

Implementado por Claude Code siguiendo las especificaciones del proyecto Baudex.
