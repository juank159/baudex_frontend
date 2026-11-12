// lib/features/dashboard/data/datasources/profitability_cache.dart
import 'dart:convert';

import '../../domain/entities/dashboard_stats.dart';
import '../../domain/services/dashboard_rules.dart';
import '../models/profitability_stats_model.dart';

/// Última rentabilidad que respondió el servidor para una organización y un
/// rango de fechas, para mostrarla sin conexión.
///
/// - Guarda y devuelve también las pérdidas (utilidad negativa): antes se
///   descartaban y el tablero escondía que el período dio pérdida.
/// - La clave incluye la organización: otra empresa en el mismo equipo nunca
///   ve cifras ajenas. Sin organización conocida no se guarda ni se lee.
class ProfitabilityCache {
  final Future<String?> Function(String key) _read;
  final Future<void> Function(String key, String value) _write;

  const ProfitabilityCache({
    required Future<String?> Function(String key) read,
    required Future<void> Function(String key, String value) write,
  })  : _read = read,
        _write = write;

  Future<void> save({
    required String? organizationId,
    required DateTime? start,
    required DateTime? end,
    required ProfitabilityStats stats,
  }) async {
    if (organizationId == null || organizationId.isEmpty) return;
    try {
      final model = ProfitabilityStatsModel.fromEntity(stats);
      await _write(
        DashboardRules.profitabilityCacheKey(
            organizationId: organizationId, start: start, end: end),
        json.encode(model.toJson()),
      );
    } catch (_) {
      // La caché es una ayuda: si falla, el tablero sigue con lo que tiene.
    }
  }

  Future<ProfitabilityStatsModel?> load({
    required String? organizationId,
    required DateTime? start,
    required DateTime? end,
  }) async {
    if (organizationId == null || organizationId.isEmpty) return null;
    try {
      final raw = await _read(DashboardRules.profitabilityCacheKey(
          organizationId: organizationId, start: start, end: end));
      if (raw == null) return null;
      return ProfitabilityStatsModel.fromJson(
          json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
