// lib/app/data/local/sync_changes_client.dart
import 'dart:convert';
import 'dart:isolate';

import 'package:dio/dio.dart';
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

  /// [items] ya convertidos a registros locales (uno por item, mismo orden),
  /// armados fuera del hilo de la pantalla. `null` si no se pidió conversión.
  final List<Object?>? rows;

  const SyncChangesPage({
    required this.items,
    required this.stamps,
    required this.deletedIds,
    required this.hasMore,
    required this.nextSince,
    required this.nextAfterId,
    required this.watermark,
    required this.resetRequired,
    this.rows,
  });

  SyncChangesPage withRows(List<Object?>? rows) => SyncChangesPage(
        items: items,
        stamps: stamps,
        deletedIds: deletedIds,
        hasMore: hasMore,
        nextSince: nextSince,
        nextAfterId: nextAfterId,
        watermark: watermark,
        resetRequired: resetRequired,
        rows: rows,
      );

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

/// Convierte los items de una página en registros locales. Debe ser una
/// función de nivel superior o estática: corre en otro isolate.
typedef SyncRowConverter = List<Object?> Function(
    List<Map<String, dynamic>> items);

/// Respuesta del servidor ya leída: quita los `{success, data}` (a veces
/// vienen dos) hasta llegar a la página.
Map<String, dynamic> unwrapSyncChangesBody(Object? body) {
  var data = body;
  while (data is Map &&
      data['data'] is Map &&
      !data.containsKey('items')) {
    data = data['data'];
  }
  if (data is! Map) {
    throw const FormatException('Respuesta de /sync/changes sin datos');
  }
  return Map<String, dynamic>.from(data);
}

/// Función suelta a propósito: lo que se envía al otro isolate es solo los
/// bytes y el convertidor (nada del cliente ni de Dio).
Future<SyncChangesPage> _parseInBackground(
        List<int> bytes, SyncRowConverter? convert) =>
    Isolate.run(
        () => parseSyncChangesPage(utf8.decode(bytes), convert),
        debugName: 'sync_changes');

/// Lee una página desde el texto de la respuesta y, si se pide, arma sus
/// registros locales. Es lo pesado de la descarga (miles de facturas con
/// ítems y pagos): por eso corre en otro isolate.
SyncChangesPage parseSyncChangesPage(String text, SyncRowConverter? convert) {
  final page = SyncChangesPage.fromJson(unwrapSyncChangesBody(jsonDecode(text)));
  return convert == null ? page : page.withRows(convert(page.items));
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
    SyncRowConverter? convert,
  }) async {
    try {
      // Se piden los bytes tal cual y se leen (UTF-8 + JSON) en otro
      // isolate: decodificar páginas de 200 facturas (cientos de KB) en el
      // hilo de la pantalla trababa la factura abierta mientras sincronizaba.
      final response = await dioClient.get(
        '/sync/changes/$entity',
        queryParameters: {
          'since': since,
          if (afterId != null) 'afterId': afterId,
          'limit': limit,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      final body = response.data;
      if (body is List<int>) return _parseInBackground(body, convert);
      if (body is String) {
        return _parseInBackground(utf8.encode(body), convert);
      }
      final page = SyncChangesPage.fromJson(unwrapSyncChangesBody(body));
      return convert == null ? page : page.withRows(convert(page.items));
    } on ServerException catch (e) {
      if (e.statusCode == 404) throw const SyncChangesUnsupportedException();
      rethrow;
    }
  }

  /// Cuántos registros vivos tiene [entity] en el servidor; `null` si el
  /// servidor aún no lo soporta.
  Future<int?> count(String entity) async {
    try {
      final response = await dioClient.get('/sync/count/$entity');
      final body = response.data;
      final data = body is Map && body['data'] is Map ? body['data'] : body;
      final value = data is Map ? data['count'] : null;
      return value is num ? value.toInt() : int.tryParse('$value');
    } on ServerException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}

/// Hasta dónde se descargó cada módulo, por negocio. Se guarda fuera de ISAR
/// (SharedPreferences) y se borra junto con los datos locales.
///
/// En Windows las preferencias son un archivo que se puede dañar (apagón
/// mientras se escribe) y entonces cada lectura lanza un error. La descarga
/// no puede morir por eso: lo que no se pudo leer o guardar se lleva en
/// memoria durante esta ejecución (antes, con el archivo dañado, la app no
/// volvía a descargar NADA del servidor).
class SyncWatermarkStore {
  static const String _prefix = 'sync_wm_v1|';

  /// Respaldo en memoria de lo que las preferencias no aceptaron. Una
  /// clave con valor null significa "borrada".
  static final Map<String, String?> _memory = {};

  /// Solo para pruebas: olvida el respaldo en memoria (app recién abierta).
  static void debugForgetMemory() => _memory.clear();

  Future<String?> _read(String key) async {
    if (_memory.containsKey(key)) return _memory[key];
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String key, String? value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ok = value == null
          ? await prefs.remove(key)
          : await prefs.setString(key, value);
      if (!ok) throw StateError('las preferencias no guardaron $key');
      _memory.remove(key);
    } catch (_) {
      _memory[key] = value;
    }
  }

  String _key(String organizationKey, String entity) =>
      '$_prefix$organizationKey|$entity';

  Future<String?> get(String organizationKey, String entity) =>
      _read(_key(organizationKey, entity));

  Future<void> set(String organizationKey, String entity, String value) =>
      _write(_key(organizationKey, entity), value);

  Future<void> remove(String organizationKey, String entity) =>
      _write(_key(organizationKey, entity), null);

  // Descarga a medias (para seguirla tras reiniciar la app). Comparte el
  // prefijo para que [clearAll] también la borre.
  String _progressKey(String organizationKey, String entity) =>
      '${_prefix}progress|$organizationKey|$entity';

  Future<Map<String, dynamic>?> getProgress(
      String organizationKey, String entity) async {
    final raw = await _read(_progressKey(organizationKey, entity));
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> setProgress(
          String organizationKey, String entity, Map<String, dynamic> value) =>
      _write(_progressKey(organizationKey, entity), jsonEncode(value));

  Future<void> removeProgress(String organizationKey, String entity) =>
      _write(_progressKey(organizationKey, entity), null);

  /// Olvida todas las marcas (de todos los negocios). Se usa cuando se
  /// borran los datos locales: la siguiente descarga debe ser completa.
  Future<void> clearAll() async {
    _memory.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key
          in prefs.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
        await prefs.remove(key);
      }
    } catch (_) {
      // Preferencias ilegibles: no hay marcas que se puedan leer tampoco.
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
