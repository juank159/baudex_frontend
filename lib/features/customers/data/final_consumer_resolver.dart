// lib/features/customers/data/final_consumer_resolver.dart
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../../../app/core/network/dio_client.dart';
import '../../../app/core/network/network_info.dart';
import '../../../app/data/local/isar_database.dart';
import '../domain/entities/customer.dart';
import 'datasources/customer_remote_datasource.dart';
import 'models/isar/isar_customer.dart';

/// CONSUMIDOR FINAL: cliente genérico de las ventas de mostrador.
///
/// Cada tenant tiene exactamente uno y lo crea el SERVIDOR (al crear el
/// tenant, o en `GET /customers/final-consumer`). La app nunca lo crea:
/// así no se duplica entre equipos ni queda un cliente temporal colgado.
///
/// Sin internet y sin tenerlo guardado en el equipo, la venta se hace con
/// el marcador [placeholderPrefix]; al sincronizar se cambia por el real.
class FinalConsumerResolver {
  static const String documentNumber = '222222222222';
  static const String name = 'Consumidor Final';
  static const String placeholderPrefix = 'fallback_consumidor_final';

  static final RegExp _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool isPlaceholderId(String? id) =>
      id != null && id.startsWith(placeholderPrefix);

  static bool isFinalConsumer(Customer? customer) {
    if (customer == null) return false;
    if (isPlaceholderId(customer.id)) return true;
    if (customer.documentNumber == documentNumber) return true;
    final fullName = '${customer.firstName} ${customer.lastName}'.trim();
    return fullName.toLowerCase() == name.toLowerCase();
  }

  /// Consumidor Final guardado en el equipo (con id real del servidor).
  static Future<Customer?> findLocal() async {
    try {
      final isar = IsarDatabase.instance.database;
      final byDocument = await isar.isarCustomers
          .filter()
          .documentNumberEqualTo(documentNumber)
          .and()
          .deletedAtIsNull()
          .findAll();
      for (final c in byDocument) {
        if (_uuid.hasMatch(c.serverId)) return c.toEntity();
      }

      final byName = await isar.isarCustomers
          .filter()
          .firstNameEqualTo('Consumidor', caseSensitive: false)
          .and()
          .lastNameEqualTo('Final', caseSensitive: false)
          .and()
          .deletedAtIsNull()
          .findAll();
      for (final c in byName) {
        if (_uuid.hasMatch(c.serverId)) return c.toEntity();
      }
    } catch (_) {}
    return null;
  }

  /// Pide al servidor el Consumidor Final del tenant (lo crea si falta) y
  /// lo guarda en el equipo para poder vender sin internet después.
  static Future<Customer?> fetchFromServer() async {
    try {
      // Sin red no se espera al servidor: la venta no se debe demorar.
      if (Get.isRegistered<NetworkInfo>() &&
          !await Get.find<NetworkInfo>().isConnected) {
        return null;
      }

      final CustomerRemoteDataSource remote;
      if (Get.isRegistered<CustomerRemoteDataSource>()) {
        remote = Get.find<CustomerRemoteDataSource>();
      } else if (Get.isRegistered<DioClient>()) {
        remote = CustomerRemoteDataSourceImpl(dioClient: Get.find<DioClient>());
      } else {
        return null;
      }

      final model = await remote
          .getFinalConsumer()
          .timeout(const Duration(seconds: 10));

      try {
        final isar = IsarDatabase.instance.database;
        await isar.writeTxn(() async {
          var isarCustomer = await isar.isarCustomers
              .filter()
              .serverIdEqualTo(model.id)
              .findFirst();
          if (isarCustomer != null) {
            isarCustomer.updateFromModel(model);
          } else {
            isarCustomer = IsarCustomer.fromModel(model);
          }
          await isar.isarCustomers.put(isarCustomer);
        });
      } catch (_) {}

      return model.toEntity();
    } catch (_) {
      return null;
    }
  }

  /// Local primero; si no está en el equipo, el servidor.
  static Future<Customer?> resolve() async {
    return await findLocal() ?? await fetchFromServer();
  }
}
