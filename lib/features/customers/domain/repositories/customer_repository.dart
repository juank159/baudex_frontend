// lib/features/customers/domain/repositories/customer_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../entities/customer.dart';
import '../entities/customer_stats.dart';

// Importar PaginatedResult desde pagination_meta.dart

/// Contrato del repositorio de clientes
abstract class CustomerRepository {
  // ==================== READ OPERATIONS ====================

  /// Obtener clientes con paginación y filtros
  Future<Either<Failure, PaginatedResult<Customer>>> getCustomers({
    int page = 1,
    int limit = 10,
    String? search,
    CustomerStatus? status,
    DocumentType? documentType,
    String? city,
    String? state,
    String? sortBy,
    String? sortOrder,
  });

  /// Obtener cliente final por defecto (sin lanzar excepciones)
  Future<Either<Failure, Customer?>> getDefaultCustomer(String customerId);

  /// Obtener cliente por ID
  Future<Either<Failure, Customer>> getCustomerById(String id);

  /// Obtener cliente por documento
  Future<Either<Failure, Customer>> getCustomerByDocument(
    DocumentType documentType,
    String documentNumber,
  );

  /// Obtener cliente por email
  Future<Either<Failure, Customer>> getCustomerByEmail(String email);

  /// Buscar clientes
  Future<Either<Failure, List<Customer>>> searchCustomers(
    String searchTerm, {
    int limit = 10,
  });

  /// Obtener estadísticas de clientes
  Future<Either<Failure, CustomerStats>> getCustomerStats();

  /// Obtener clientes con facturas vencidas
  Future<Either<Failure, List<Customer>>> getCustomersWithOverdueInvoices();

  /// Obtener top clientes por compras
  Future<Either<Failure, List<Customer>>> getTopCustomers({int limit = 10});

  // ==================== WRITE OPERATIONS ====================

  /// Crear cliente
  Future<Either<Failure, Customer>> createCustomer({
    required String firstName,
    required String lastName,
    String? companyName,
    required String email,
    String? phone,
    String? mobile,
    required DocumentType documentType,
    required String documentNumber,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    CustomerStatus? status,
    double? creditLimit,
    int? paymentTerms,
    DateTime? birthDate,
    String? notes,
    Map<String, dynamic>? metadata,
  });

  /// Actualizar cliente
  Future<Either<Failure, Customer>> updateCustomer({
    required String id,
    String? firstName,
    String? lastName,
    String? companyName,
    String? email,
    String? phone,
    String? mobile,
    DocumentType? documentType,
    String? documentNumber,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    CustomerStatus? status,
    double? creditLimit,
    int? paymentTerms,
    DateTime? birthDate,
    String? notes,
    Map<String, dynamic>? metadata,
  });

  /// Actualizar estado del cliente
  Future<Either<Failure, Customer>> updateCustomerStatus({
    required String id,
    required CustomerStatus status,
  });

  /// Actualizar balance del cliente
  Future<Either<Failure, Customer>> updateCustomerBalance({
    required String id,
    required double amount,
    required String operation, // 'add' | 'subtract'
  });

  /// Eliminar cliente (soft delete)
  Future<Either<Failure, Unit>> deleteCustomer(String id);

  /// Restaurar cliente
  Future<Either<Failure, Customer>> restoreCustomer(String id);

  // ==================== VALIDATION OPERATIONS ====================

  /// Verificar si email está disponible
  Future<Either<Failure, bool>> isEmailAvailable(
    String email, {
    String? excludeId,
  });

  /// Verificar si documento está disponible
  Future<Either<Failure, bool>> isDocumentAvailable(
    DocumentType documentType,
    String documentNumber, {
    String? excludeId,
  });

  /// Verificar si el cliente puede realizar una compra
  Future<Either<Failure, Map<String, dynamic>>> canMakePurchase({
    required String customerId,
    required double amount,
  });

  /// Obtener resumen financiero del cliente
  Future<Either<Failure, Map<String, dynamic>>> getCustomerFinancialSummary(
    String customerId,
  );

  // ==================== CACHE OPERATIONS ====================

  /// Obtener clientes desde cache
  Future<Either<Failure, List<Customer>>> getCachedCustomers();

  /// Limpiar cache de clientes
  Future<Either<Failure, Unit>> clearCustomerCache();
}
