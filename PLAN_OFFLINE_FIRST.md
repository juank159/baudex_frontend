# PLAN DE IMPLEMENTACIÓN: SINCRONIZACIÓN OFFLINE-FIRST

## FASE 0: INFRAESTRUCTURA BASE (SEMANA 1)

### 🎯 Objetivo
Crear la infraestructura base para sincronización offline sin tocar ningún módulo existente. La aplicación seguirá funcionando normalmente.

### 📋 Tareas a Realizar

#### 1. Configurar Isar Database
- **Archivo:** `lib/app/data/local/isar_database.dart`
- **Descripción:** Inicializar base de datos Isar para almacenamiento local
- **Estado:** ⏳ Por implementar

#### 2. Crear SyncQueue (Cola de Operaciones)
- **Archivo:** `lib/app/data/local/sync_queue.dart`
- **Descripción:** Modelo Isar para almacenar operaciones pendientes (crear/editar/eliminar)
- **Estado:** ⏳ Por implementar

#### 3. Implementar SyncService (Coordinador de Sincronización)
- **Archivo:** `lib/app/data/local/sync_service.dart`
- **Descripción:** Servicio que detecta conectividad y sincroniza automáticamente
- **Funcionalidades:**
  - Detectar cambios de conectividad (wifi/mobile)
  - Encolar operaciones pendientes
  - Sincronizar automáticamente cuando vuelve internet
  - Trackear estado de sincronización
- **Estado:** ⏳ Por implementar

#### 4. Crear Widget de Estado de Sincronización
- **Archivo:** `lib/app/presentation/widgets/sync_status_indicator.dart`
- **Descripción:** Widget que muestra estado actual de sincronización
- **Estados:**
  - ⏳ Sincronizando (spinner)
  - ☁️ Pendiente (badge con número)
  - ✅ Sincronizado (ícono verde)
  - ❌ Error (ícono rojo con tooltip)
- **Estado:** ⏳ Por implementar

#### 5. Registrar Servicios en App Binding
- **Archivo:** `lib/app/bindings/app_binding.dart`
- **Descripción:** Registrar IsarDatabase, SyncService en GetX DI
- **Estado:** ⏳ Por implementar

#### 6. Generar Código con Build Runner
- **Comando:** `dart run build_runner build --delete-conflicting-outputs`
- **Descripción:** Generar código de Isar (schemas, collections)
- **Estado:** ⏳ Por implementar

### ✅ Criterios de Éxito

- [ ] Isar se inicializa sin errores al abrir la app
- [ ] SyncQueue puede guardar operaciones en Isar
- [ ] SyncService detecta cambios de conectividad
- [ ] Widget muestra estado correcto
- [ ] App sigue funcionando normalmente (sin regresiones)
- [ ] Cero errores de compilación

### 🧪 Plan de Testing

#### Test 1: Inicialización de Isar
```dart
// Verificar que Isar se inicializa
1. Abrir app
2. Verificar logs: "Isar database initialized"
3. No debe haber errores
```

#### Test 2: SyncService Detecta Conectividad
```dart
// Simular pérdida de conexión
1. Abrir app en modo online
2. Desactivar WiFi/Ethernet
3. Verificar logs: "Connectivity lost"
4. Reactivar WiFi
5. Verificar logs: "Connectivity restored"
```

#### Test 3: Guardar Operación en SyncQueue
```dart
// Desde Dart DevTools
1. Ejecutar:
   final op = SyncOperation()
     ..entityType = 'Test'
     ..entityId = '123'
     ..operationType = SyncOperationType.create
     ..status = SyncStatus.pending
     ..payload = '{}'
     ..createdAt = DateTime.now();

   await Get.find<IsarDatabase>().isar.writeTxn(() async {
     await Get.find<IsarDatabase>().isar.syncOperations.put(op);
   });

2. Verificar que se guardó
3. Abrir Isar Inspector (http://localhost:39000)
4. Ver operación en colección syncOperations
```

#### Test 4: Widget de Estado
```dart
// Agregar widget al AppBar de cualquier pantalla
1. Modificar temporalmente un screen
2. Agregar SyncStatusIndicator en AppBar
3. Verificar que muestra ícono de sincronizado
4. Crear operación pendiente manualmente
5. Verificar que muestra badge con "1 pendiente"
```

### 🔄 Rollback Plan

Si algo sale mal:

```bash
# 1. Revertir cambios con git
git checkout HEAD -- lib/app/data/local/
git checkout HEAD -- lib/app/bindings/app_binding.dart

# 2. Limpiar código generado
rm -rf lib/**/*.g.dart

# 3. Reinstalar dependencias
flutter clean
flutter pub get

# 4. Ejecutar app
flutter run
```

### 📁 Archivos que se van a crear

```
lib/
└── app/
    ├── data/
    │   └── local/
    │       ├── isar_database.dart          ✅ NUEVO
    │       ├── sync_queue.dart             ✅ NUEVO
    │       ├── sync_queue.g.dart           🤖 GENERADO
    │       └── sync_service.dart           ✅ NUEVO
    ├── presentation/
    │   └── widgets/
    │       └── sync_status_indicator.dart  ✅ NUEVO
    └── bindings/
        └── app_binding.dart                ✏️ MODIFICAR
```

### ⏱️ Estimación de Tiempo

| Tarea | Tiempo Estimado |
|-------|-----------------|
| 1. IsarDatabase | 30 min |
| 2. SyncQueue | 20 min |
| 3. SyncService | 1 hora |
| 4. SyncStatusIndicator | 30 min |
| 5. App Binding | 15 min |
| 6. Build Runner + Testing | 1 hora |
| **TOTAL** | **≈ 3.5 horas** |

### 🔐 Seguridad y Consideraciones

1. **Multitenancy:**
   - Crear base de datos separada por tenant
   - Formato: `baudex_{tenant_slug}_offline.isar`

2. **Datos Sensibles:**
   - NO guardar tokens en Isar
   - Mantener tokens en SecureStorage

3. **Backup:**
   - Crear backup automático antes de inicializar Isar

### 📊 Próximos Pasos Después de Fase 0

Una vez completada Fase 0:

1. **Validar que todo funciona** (1 día de pruebas)
2. **Decidir continuar con Fase 1** (Categorías)
3. **Documentar aprendizajes** de Fase 0

---

## NOTAS IMPORTANTES

⚠️ **NO TOCAR NINGÚN MÓDULO EXISTENTE** en esta fase
⚠️ **LA APP DEBE SEGUIR FUNCIONANDO IGUAL** que antes
⚠️ **HACER COMMIT DESPUÉS DE CADA TAREA** completada
⚠️ **PROBAR ANTES DE CONTINUAR** a la siguiente tarea

---

## Estado Actual

- **Iniciado:** [FECHA]
- **Completado:** Pendiente
- **Responsable:** Claude + Usuario
- **Branch:** [NOMBRE DEL BRANCH]

---

## Registro de Cambios

### [FECHA] - Inicio Fase 0
- ✅ Documento de plan creado
- ⏳ Implementación pendiente
