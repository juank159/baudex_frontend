// lib/features/invoices/domain/services/invoice_history_lookup.dart
import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/models/pagination_meta.dart';
import '../entities/invoice.dart';
import '../usecases/get_invoices_usecase.dart';

/// Lo que la lista de facturas necesita saber mientras el historial todavía
/// se está descargando al equipo.
///
/// La lista SIEMPRE se pinta con lo que hay en el equipo. Si el historial
/// no ha terminado de bajar puede faltar alguna factura antigua: la pantalla
/// lo avisa y, cuando una búsqueda no encuentra nada, pregunta al servidor
/// por detrás (sin bloquear) y agrega lo que llegue.
abstract class InvoiceHistoryLookup {
  /// ¿El historial de facturas aún no termina de descargarse a este equipo?
  Future<bool> isHistoryDownloading();

  /// Pregunta SOLO al servidor (no lee el equipo). Lo que llega queda
  /// guardado en el equipo. Sin internet devuelve un fallo.
  Future<Either<Failure, PaginatedResult<Invoice>>> getInvoicesFromServer(
    GetInvoicesParams params,
  );
}
