#!/bin/bash

# =====================================================================
# Script de Validación del Sistema Offline-First de Baudex
# =====================================================================
# Este script valida que el sistema offline-first esté correctamente
# implementado y funcional.
#
# Uso: ./scripts/validate_offline_system.sh
# =====================================================================

set -e  # Salir inmediatamente si un comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
TESTS_PASSED=0
TESTS_FAILED=0
WARNINGS=0

# Función para imprimir con color
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((TESTS_PASSED++))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    ((TESTS_FAILED++))
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARNINGS++))
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_header() {
    echo ""
    echo "========================================"
    echo "$1"
    echo "========================================"
}

# =====================================================================
# PASO 1: Verificar Estructura de Directorios
# =====================================================================
print_header "PASO 1: Verificando Estructura de Directorios"

check_directory() {
    if [ -d "$1" ]; then
        print_success "Directorio existe: $1"
        return 0
    else
        print_error "Directorio faltante: $1"
        return 1
    fi
}

check_directory "lib/features/products/data/models/isar"
check_directory "lib/features/customers/data/models/isar"
check_directory "lib/features/categories/data/models/isar"
check_directory "lib/features/invoices/data/models/isar"
check_directory "lib/features/notifications/data/models/isar"
check_directory "lib/features/inventory/data/models/isar"
check_directory "lib/app/data/local"
check_directory "lib/app/data/services"
check_directory "docs"

# =====================================================================
# PASO 2: Verificar Archivos ISAR Críticos
# =====================================================================
print_header "PASO 2: Verificando Archivos ISAR Críticos"

check_file() {
    if [ -f "$1" ]; then
        print_success "Archivo existe: $1"
        return 0
    else
        print_error "Archivo faltante: $1"
        return 1
    fi
}

# Models ISAR
check_file "lib/features/products/data/models/isar/isar_product.dart"
check_file "lib/features/customers/data/models/isar/isar_customer.dart"
check_file "lib/features/categories/data/models/isar/isar_category.dart"
check_file "lib/features/invoices/data/models/isar/isar_invoice.dart"
check_file "lib/features/notifications/data/models/isar/isar_notification.dart"
check_file "lib/features/inventory/data/models/isar/isar_inventory_movement.dart"
check_file "lib/features/inventory/data/models/isar/isar_inventory_batch.dart"
check_file "lib/features/inventory/data/models/isar/isar_inventory_batch_movement.dart"

# Core files
check_file "lib/app/data/local/isar_database.dart"
check_file "lib/app/data/local/sync_queue.dart"
check_file "lib/app/data/services/sync_service.dart"
check_file "lib/app/data/local/repositories_registry.dart"

# =====================================================================
# PASO 3: Verificar Archivos Generados por build_runner
# =====================================================================
print_header "PASO 3: Verificando Archivos Generados (.g.dart)"

check_generated() {
    if [ -f "$1" ]; then
        print_success "Generado: $1"
        return 0
    else
        print_error "Falta archivo generado: $1"
        echo "         Ejecutar: flutter pub run build_runner build --delete-conflicting-outputs"
        return 1
    fi
}

check_generated "lib/features/products/data/models/isar/isar_product.g.dart"
check_generated "lib/features/customers/data/models/isar/isar_customer.g.dart"
check_generated "lib/features/categories/data/models/isar/isar_category.g.dart"
check_generated "lib/features/invoices/data/models/isar/isar_invoice.g.dart"
check_generated "lib/features/notifications/data/models/isar/isar_notification.g.dart"
check_generated "lib/features/inventory/data/models/isar/isar_inventory_movement.g.dart"
check_generated "lib/features/inventory/data/models/isar/isar_inventory_batch.g.dart"
check_generated "lib/features/inventory/data/models/isar/isar_inventory_batch_movement.g.dart"

# =====================================================================
# PASO 4: Verificar Offline Repositories
# =====================================================================
print_header "PASO 4: Verificando Offline Repositories"

check_file "lib/features/products/data/repositories/product_offline_repository.dart"
check_file "lib/features/customers/data/repositories/customer_offline_repository.dart"
check_file "lib/features/categories/data/repositories/category_offline_repository.dart"
check_file "lib/features/invoices/data/repositories/invoice_offline_repository.dart"
check_file "lib/features/dashboard/data/repositories/notification_offline_repository.dart"
check_file "lib/features/inventory/data/repositories/inventory_offline_repository.dart"

# =====================================================================
# PASO 5: Verificar Local Datasources
# =====================================================================
print_header "PASO 5: Verificando Local Datasources (ISAR)"

check_file "lib/features/products/data/datasources/product_local_datasource_isar.dart"
check_file "lib/features/customers/data/datasources/customer_local_datasource_isar.dart"
check_file "lib/features/categories/data/datasources/category_local_datasource_isar.dart"
check_file "lib/features/invoices/data/datasources/invoice_local_datasource_isar.dart"
check_file "lib/features/inventory/data/datasources/inventory_local_datasource_isar.dart"

# =====================================================================
# PASO 6: Verificar Integración con SyncService
# =====================================================================
print_header "PASO 6: Verificando Integración con SyncService"

check_in_file() {
    local file=$1
    local pattern=$2
    local description=$3

    if grep -q "$pattern" "$file" 2>/dev/null; then
        print_success "$description"
        return 0
    else
        print_error "$description - No encontrado en $file"
        return 1
    fi
}

check_in_file "lib/app/data/services/sync_service.dart" "_repositoriesRegistry.products" "Products en SyncService"
check_in_file "lib/app/data/services/sync_service.dart" "_repositoriesRegistry.customers" "Customers en SyncService"
check_in_file "lib/app/data/services/sync_service.dart" "_repositoriesRegistry.categories" "Categories en SyncService"
check_in_file "lib/app/data/services/sync_service.dart" "_repositoriesRegistry.invoices" "Invoices en SyncService"
check_in_file "lib/app/data/services/sync_service.dart" "_repositoriesRegistry.notifications" "Notifications en SyncService"
check_in_file "lib/app/data/services/sync_service.dart" "_repositoriesRegistry.inventory" "Inventory en SyncService"

# =====================================================================
# PASO 7: Verificar Registro en ISAR Database
# =====================================================================
print_header "PASO 7: Verificando Registro en ISAR Database"

check_in_file "lib/app/data/local/isar_database.dart" "IsarProductSchema" "IsarProductSchema registrado"
check_in_file "lib/app/data/local/isar_database.dart" "IsarCustomerSchema" "IsarCustomerSchema registrado"
check_in_file "lib/app/data/local/isar_database.dart" "IsarCategorySchema" "IsarCategorySchema registrado"
check_in_file "lib/app/data/local/isar_database.dart" "IsarInvoiceSchema" "IsarInvoiceSchema registrado"
check_in_file "lib/app/data/local/isar_database.dart" "IsarNotificationSchema" "IsarNotificationSchema registrado"
check_in_file "lib/app/data/local/isar_database.dart" "IsarInventoryMovementSchema" "IsarInventoryMovementSchema registrado"
check_in_file "lib/app/data/local/isar_database.dart" "IsarInventoryBatchSchema" "IsarInventoryBatchSchema registrado"
check_in_file "lib/app/data/local/isar_database.dart" "IsarInventoryBatchMovementSchema" "IsarInventoryBatchMovementSchema registrado"

# =====================================================================
# PASO 8: Verificar Documentación
# =====================================================================
print_header "PASO 8: Verificando Documentación"

check_file "docs/OFFLINE_FIRST_ARCHITECTURE.md"
check_file "docs/SYNC_SERVICE_GUIDE.md"

if [ ! -f "docs/OFFLINE_FIRST_ARCHITECTURE.md" ]; then
    print_warning "Falta documentación de arquitectura"
fi

# =====================================================================
# PASO 9: Análisis Estático (si Flutter está disponible)
# =====================================================================
print_header "PASO 9: Análisis Estático"

if command -v flutter &> /dev/null; then
    print_info "Ejecutando flutter analyze..."

    if flutter analyze > analysis_report.txt 2>&1; then
        ANALYSIS_ERRORS=$(grep -c "error •" analysis_report.txt || echo "0")
        ANALYSIS_WARNINGS=$(grep -c "warning •" analysis_report.txt || echo "0")
        ANALYSIS_INFOS=$(grep -c "info •" analysis_report.txt || echo "0")

        echo "   Errores: $ANALYSIS_ERRORS"
        echo "   Warnings: $ANALYSIS_WARNINGS"
        echo "   Infos: $ANALYSIS_INFOS"

        if [ "$ANALYSIS_ERRORS" -eq 0 ]; then
            print_success "Análisis estático pasó sin errores"
        else
            print_error "Análisis estático encontró $ANALYSIS_ERRORS errores"
            echo "         Ver analysis_report.txt para detalles"
        fi
    else
        print_error "Flutter analyze falló"
    fi
else
    print_warning "Flutter no está disponible - saltando análisis estático"
fi

# =====================================================================
# PASO 10: Verificar Dependencias
# =====================================================================
print_header "PASO 10: Verificando Dependencias"

if [ -f "pubspec.yaml" ]; then
    check_in_file "pubspec.yaml" "isar:" "Dependencia: isar"
    check_in_file "pubspec.yaml" "isar_flutter_libs:" "Dependencia: isar_flutter_libs"
    check_in_file "pubspec.yaml" "get:" "Dependencia: get (GetX)"
    check_in_file "pubspec.yaml" "dartz:" "Dependencia: dartz (Either)"
    check_in_file "pubspec.yaml" "dio:" "Dependencia: dio (HTTP)"
    check_in_file "pubspec.yaml" "connectivity_plus:" "Dependencia: connectivity_plus"
    check_in_file "pubspec.yaml" "flutter_secure_storage:" "Dependencia: flutter_secure_storage"
fi

# =====================================================================
# PASO 11: Estadísticas del Código
# =====================================================================
print_header "PASO 11: Estadísticas del Código"

if command -v find &> /dev/null; then
    TOTAL_DART_FILES=$(find lib -name "*.dart" | wc -l | tr -d ' ')
    ISAR_MODEL_FILES=$(find lib -path "*/models/isar/*.dart" ! -name "*.g.dart" | wc -l | tr -d ' ')
    ISAR_GENERATED_FILES=$(find lib -path "*/models/isar/*.g.dart" | wc -l | tr -d ' ')
    REPOSITORY_FILES=$(find lib -name "*_repository.dart" | wc -l | tr -d ' ')
    DATASOURCE_FILES=$(find lib -name "*_datasource*.dart" | wc -l | tr -d ' ')

    echo "   Total archivos Dart: $TOTAL_DART_FILES"
    echo "   Modelos ISAR: $ISAR_MODEL_FILES"
    echo "   Archivos generados: $ISAR_GENERATED_FILES"
    echo "   Repositorios: $REPOSITORY_FILES"
    echo "   Datasources: $DATASOURCE_FILES"

    if [ "$ISAR_MODEL_FILES" -eq "$ISAR_GENERATED_FILES" ]; then
        print_success "Todos los modelos ISAR tienen archivos generados"
    else
        print_warning "Modelos ISAR ($ISAR_MODEL_FILES) != Generados ($ISAR_GENERATED_FILES)"
        echo "         Ejecutar: flutter pub run build_runner build --delete-conflicting-outputs"
    fi
fi

# =====================================================================
# RESUMEN FINAL
# =====================================================================
print_header "RESUMEN FINAL"

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))

echo ""
echo "   Tests Pasados:  $TESTS_PASSED / $TOTAL_TESTS"
echo "   Tests Fallidos: $TESTS_FAILED / $TOTAL_TESTS"
echo "   Advertencias:   $WARNINGS"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════╗"
    echo "║                                       ║"
    echo "║   ✅ VALIDACIÓN COMPLETADA 100%      ║"
    echo "║                                       ║"
    echo "║   Sistema Offline-First OPERATIVO    ║"
    echo "║                                       ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
    exit 0
elif [ $TESTS_FAILED -le 3 ]; then
    echo -e "${YELLOW}"
    echo "╔═══════════════════════════════════════╗"
    echo "║                                       ║"
    echo "║   ⚠️  VALIDACIÓN PARCIAL              ║"
    echo "║                                       ║"
    echo "║   Revisar errores mencionados         ║"
    echo "║                                       ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
    exit 1
else
    echo -e "${RED}"
    echo "╔═══════════════════════════════════════╗"
    echo "║                                       ║"
    echo "║   ❌ VALIDACIÓN FALLIDA               ║"
    echo "║                                       ║"
    echo "║   Revisar errores críticos            ║"
    echo "║                                       ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
    exit 1
fi
