// lib/features/breb/presentation/controllers/breb_payment_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import '../../data/breb_api.dart';
import '../../domain/breb_charge.dart';

/// En qué va el cobro, para la pantalla.
enum BrebPaymentPhase { creating, waiting, confirmed, expired, cancelled, failed }

/// Lleva un cobro Bre-B de principio a fin: lo crea, pregunta al servidor
/// cada pocos segundos si ya llegó el aviso del banco y avisa cuando la
/// venta quedó pagada.
class BrebPaymentController extends GetxController {
  final BrebApi _api;

  /// Cada cuánto se pregunta por el cobro. Igual que La Bomba.
  final Duration pollEvery;

  BrebPaymentController(this._api, {this.pollEvery = const Duration(seconds: 3)});

  final phase = BrebPaymentPhase.creating.obs;
  final charge = Rxn<BrebCharge>();
  final state = Rxn<BrebChargeState>();
  final errorMessage = RxnString();
  final remaining = '0:00'.obs;

  Timer? _poll;
  Timer? _clock;
  bool _asking = false;

  /// Factura creada (o cobrada) cuando el pago queda confirmado.
  String? get invoiceId => state.value?.invoiceId;

  /// Cobro de una venta nueva del punto de venta.
  Future<void> startForSale({required Map<String, dynamic> draft, required double amount}) =>
      _start(() => _api.createChargeForSale(draft: draft, amount: amount));

  /// Cobro de una factura que ya existe y se debe.
  Future<void> startForInvoice(String invoiceId) =>
      _start(() => _api.createChargeForInvoice(invoiceId));

  Future<void> _start(Future<BrebCharge> Function() create) async {
    _stopTimers();
    phase.value = BrebPaymentPhase.creating;
    errorMessage.value = null;
    try {
      final created = await create();
      if (isClosed) {
        // Cerraron el diálogo mientras se creaba: no dejar el cobro vivo.
        unawaited(_api.cancel(created.chargeId).catchError((_) {}));
        return;
      }
      charge.value = created;
      phase.value = BrebPaymentPhase.waiting;
      _tick();
      _clock = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      _poll = Timer.periodic(pollEvery, (_) => checkNow());
    } on BrebException catch (e) {
      errorMessage.value = e.message;
      phase.value = BrebPaymentPhase.failed;
    } catch (e) {
      errorMessage.value = 'No se pudo iniciar el cobro Bre-B.';
      phase.value = BrebPaymentPhase.failed;
    }
  }

  void _tick() {
    final current = charge.value;
    if (current == null) return;
    remaining.value = brebRemainingLabel(current.expiresAt, DateTime.now());
  }

  /// Pregunta al servidor por el cobro. Un fallo de red no cancela nada: se
  /// vuelve a intentar en la siguiente vuelta.
  Future<void> checkNow() async {
    final current = charge.value;
    if (current == null || _asking || phase.value != BrebPaymentPhase.waiting) return;
    _asking = true;
    try {
      final latest = await _api.status(current.chargeId);
      if (isClosed || phase.value != BrebPaymentPhase.waiting) return;
      state.value = latest;
      switch (latest.status) {
        case BrebChargeStatus.matched:
          _stopTimers();
          phase.value = BrebPaymentPhase.confirmed;
          break;
        case BrebChargeStatus.expired:
          _stopTimers();
          phase.value = BrebPaymentPhase.expired;
          break;
        case BrebChargeStatus.cancelled:
          _stopTimers();
          phase.value = BrebPaymentPhase.cancelled;
          break;
        case BrebChargeStatus.pending:
          break;
      }
    } catch (_) {
      // Sin respuesta esta vez; el pago, si llegó, se verá en la próxima.
    } finally {
      _asking = false;
    }
  }

  /// El cliente no pagó o cambió de método: se cancela el cobro.
  ///
  /// Antes de cancelar se pregunta una última vez: si el pago entró en ese
  /// instante, la venta ya existe y NO se debe cobrar de nuevo por otro medio.
  /// Devuelve `true` si quedó cancelado y `false` si resultó pagado.
  Future<bool> cancel() async {
    final current = charge.value;
    if (current == null || phase.value != BrebPaymentPhase.waiting) return true;
    await checkNow();
    if (phase.value == BrebPaymentPhase.confirmed) return false;
    _stopTimers();
    try {
      await _api.cancel(current.chargeId);
      final latest = await _api.status(current.chargeId);
      state.value = latest;
      if (latest.status == BrebChargeStatus.matched) {
        phase.value = BrebPaymentPhase.confirmed;
        return false;
      }
    } catch (_) {
      // Sin conexión: el cobro vence solo en el servidor.
    }
    phase.value = BrebPaymentPhase.cancelled;
    return true;
  }

  void _stopTimers() {
    _poll?.cancel();
    _clock?.cancel();
    _poll = null;
    _clock = null;
  }

  @override
  void onClose() {
    _stopTimers();
    super.onClose();
  }
}
