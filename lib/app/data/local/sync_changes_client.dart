// lib/app/data/local/sync_changes_client.dart
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/dio_client.dart';

/// Una página de la descarga incremental (GET /sync/changes/:entity).
class SyncChangesPage {
  /// Registros nuevos o modificados, con la misma forma que el listado del
  /// módulo (se interpretan con los mismos modelos de siempre).
  final List<Map<String, dynamic>> items;

  /// `updated_at` exacto de cada registro de [items] (UTC, microsegundos).
  final List<String> stamps;

  /// IDs borrados en el servidor desde la marca pedida.
  final List<String> deletedIds;

  final bool hasMore;
  final String? nextSince;
  final String? nextAfterId;

  /// Marca para la próxima descarga (solo en la primera página).
  final String? watermark;

  /// La marca es demasiado vieja: hay que descargar todo de nuevo.
  final bool resetRequired;

  const SyncChangesPage({
    required this.items,
    required this.stamps,
    required this.deletedIds,
    required this.hasMore,
    required this.nextSince,
    required this.nextAfterId,
    required this.watermark,
    required this.resetRequired,
  });

  factory SyncChangesPage.fromJson(Map<String, dynamic> json) {
    final next = json['next'] as Map<String, dynamic>?;
    return SyncChangesPage(
      items: (json['items'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
      stamps: (json['stamps'] as List? ?? const [])
          .map((s) => s.toString())
          .toList(),
      deletedIds: (json['deletedIds'] as List? ?? const [])
          .map((id) => id.toString())
          .toList(),
      hasMore: json['hasMore'] == true,
      nextSince: next?['since']?.toString(),
      nextAfterId: next?['afterId']?.toString(),
      watermark: json['watermark']?.toString(),
      resetRequired: json['resetRequired'] == true,
    );
  }
}

/// El servidor todavía no tiene la descarga incremental (versión anterior
/// del backend): se usa la descarga completa de siempre.
class SyncChangesUnsupportedException implements Exception {
  const SyncChangesUnsupportedException();
}

class SyncChangesClient {
  /// Marca "desde siempre": descarga completa.
  static const String epoch = '1970-01-01T00:00:00.000000Z';

  final DioClient dioClient;
  SyncChangesClient(this.dioClient);

  Future<SyncChangesPage> fetch(
    String entity, {
    required String since,
    String? afterId,
    int limit = 200,
  }) async {
    try {
      final response = await dioClient.get(
        '/sync/changes/$entity',
        queryParameters: {
          'since': since,
          if (afterId != null) 'afterId': afterId,
          'limit': limit,
        },
      );
      final body = response.data;
      final data = body is Map && body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : Map<String, dynamic>.from(body as Map);
      return SyncChangesPage.fromJson(data);
    } on ServerException catch (e) {
      if (e.statusCode == 404) throw const SyncChangesUnsupportedException();
      rethrow;
    }
  }
}

/// Hasta dónde se descargó cada módulo, por negocio. Se guarda fuera de ISAR
/// (SharedPreferences) y se borra junto con los datos locales.
class SyncWatermarkStore {
  static const String _prefix = 'sync_wm_v1|';

  String _key(String organizationKey, String entity) =>
      '$_prefix$organizationKey|$entity';

  Future<String?> get(String organizationKey, String entity) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(organizationKey, entity));
  }

  Future<void> set(String organizationKey, String entity, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(organizationKey, entity), value);
  }

  Future<void> remove(String organizationKey, String entity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(organizationKey, entity));
  }

  /// Olvida todas las marcas (de todos los negocios). Se usa cuando se
  /// borran los datos locales: la siguiente descarga debe ser completa.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      await prefs.remove(key);
    }
  }

  /// Marca a guardar al terminar: la del servidor, pero nunca después de un
  /// cambio que no se pudo aplicar (registro con cambios locales sin subir).
  /// Así ese registro vuelve a bajar en la próxima descarga.
  static String safeWatermark(String serverWatermark, String? earliestSkipped) {
    if (earliestSkipped == null) return serverWatermark;
    final skipped = DateTime.tryParse(earliestSkipped);
    final server = DateTime.tryParse(serverWatermark);
    if (skipped == null || server == null) return serverWatermark;
    final justBefore = skipped.toUtc().subtract(const Duration(microseconds: 1));
    return justBefore.isBefore(server)
        ? justBefore.toIso8601String()
        : serverWatermark;
  }
}
