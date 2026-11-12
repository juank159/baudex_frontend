// lib/features/breb/presentation/widgets/breb_payment_dialog.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../data/breb_api.dart';
import '../../domain/breb_charge.dart';
import '../controllers/breb_payment_controller.dart';

/// Cobro por Bre-B: muestra el QR con el monto, espera el aviso del banco y
/// se cierra sola cuando la venta queda pagada.
///
/// Devuelve el id de la factura (creada o cobrada) si el pago se confirmó, o
/// `null` si el cajero canceló, el cobro venció o no se pudo iniciar.
class BrebPaymentDialog extends StatefulWidget {
  /// Venta nueva: el borrador de la factura (mismo cuerpo de "crear factura").
  final Map<String, dynamic>? draft;

  /// Valor de la venta nueva.
  final double? amount;

  /// Factura que ya existe y se debe (cartera).
  final String? invoiceId;

  /// Para pruebas: controlador ya armado.
  final BrebPaymentController? controller;

  const BrebPaymentDialog.forSale({
    super.key,
    required Map<String, dynamic> this.draft,
    required double this.amount,
    this.controller,
  }) : invoiceId = null;

  const BrebPaymentDialog.forInvoice({
    super.key,
    required String this.invoiceId,
    this.controller,
  })  : draft = null,
        amount = null;

  /// Abre el cobro de una venta nueva. Devuelve el id de la factura creada.
  static Future<String?> showForSale(
    BuildContext context, {
    required Map<String, dynamic> draft,
    required double amount,
  }) =>
      showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => BrebPaymentDialog.forSale(draft: draft, amount: amount),
      );

  /// Abre el cobro de una factura que se debe. Devuelve su id si quedó pagada.
  static Future<String?> showForInvoice(BuildContext context, String invoiceId) =>
      showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => BrebPaymentDialog.forInvoice(invoiceId: invoiceId),
      );

  @override
  State<BrebPaymentDialog> createState() => _BrebPaymentDialogState();
}

class _BrebPaymentDialogState extends State<BrebPaymentDialog> {
  late final BrebPaymentController _controller;
  late final bool _ownsController;
  Worker? _phaseWorker;
  int _selectedLlave = 0;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? BrebPaymentController(BrebApi(Get.find<DioClient>()));
    if (_ownsController) _controller.onInit();

    // Pago confirmado: se deja ver un momento y se cierra con la factura.
    _phaseWorker = ever<BrebPaymentPhase>(_controller.phase, (phase) {
      if (phase == BrebPaymentPhase.confirmed) {
        Future.delayed(const Duration(milliseconds: 1500), () => _close(_controller.invoiceId));
      }
    });
    _start();
  }

  void _start() {
    setState(() => _selectedLlave = 0);
    if (widget.invoiceId != null) {
      _controller.startForInvoice(widget.invoiceId!);
    } else {
      _controller.startForSale(draft: widget.draft!, amount: widget.amount!);
    }
  }

  void _close(String? invoiceId) {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.of(context).pop(invoiceId);
  }

  Future<void> _cancel() async {
    final cancelled = await _controller.cancel();
    // Si el pago entró justo antes de cancelar, la venta ya existe: se sigue
    // el camino de "confirmado" (lo cierra el escucha de la fase).
    if (cancelled) _close(null);
  }

  @override
  void dispose() {
    _phaseWorker?.dispose();
    if (_ownsController) {
      // Si se cierra sin terminar (p. ej. botón atrás), no dejar el cobro vivo.
      if (_controller.phase.value == BrebPaymentPhase.waiting) {
        unawaited(_controller.cancel());
      }
      _controller.onClose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Obx(() {
              switch (_controller.phase.value) {
                case BrebPaymentPhase.creating:
                  return _message(
                    icon: const SizedBox(width: 36, height: 36, child: CircularProgressIndicator()),
                    title: 'Preparando el cobro Bre-B…',
                  );
                case BrebPaymentPhase.waiting:
                  return _waiting(_controller.charge.value!);
                case BrebPaymentPhase.confirmed:
                  return _message(
                    icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
                    title: '¡Pago recibido!',
                    detail: [
                      if ((_controller.state.value?.payerName ?? '').isNotEmpty)
                        'Pagó: ${_controller.state.value!.payerName}',
                      if ((_controller.state.value?.bankLabel ?? '').isNotEmpty)
                        'Banco: ${_controller.state.value!.bankLabel}',
                    ].join('\n'),
                  );
                case BrebPaymentPhase.expired:
                  return _message(
                    icon: const Icon(Icons.timer_off, color: Colors.orange, size: 56),
                    title: 'El cobro venció',
                    detail: 'No llegó el aviso del banco a tiempo. Si el cliente sí pagó, '
                        'el pago aparece en "Pagos Bre-B recibidos" para asignarlo.',
                    actions: [_closeButton(), _receivedButton(), _retryButton()],
                  );
                case BrebPaymentPhase.cancelled:
                  return _message(
                    icon: const Icon(Icons.cancel, color: Colors.grey, size: 56),
                    title: 'Cobro cancelado',
                    actions: [_closeButton()],
                  );
                case BrebPaymentPhase.failed:
                  return _message(
                    icon: const Icon(Icons.error_outline, color: Colors.red, size: 56),
                    title: 'No se pudo iniciar el cobro',
                    detail: _controller.errorMessage.value,
                    actions: [_closeButton(), _retryButton()],
                  );
              }
            }),
          ),
        ),
      ),
    );
  }

  Widget _waiting(BrebCharge charge) {
    final llaves = charge.llaves;
    final index = _selectedLlave.clamp(0, llaves.isEmpty ? 0 : llaves.length - 1);
    final llave = llaves.isEmpty ? null : llaves[index];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Cobro Bre-B', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            AppFormatters.formatCurrency(charge.amount),
            key: const Key('breb-amount'),
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
          ),
          if (charge.adjustment > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Se cobra ${AppFormatters.formatCurrency(charge.adjustment)} menos de '
                '${AppFormatters.formatCurrency(charge.requestedAmount)} para identificar este pago. '
                'El cliente debe transferir el valor exacto.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
              ),
            ),
          const SizedBox(height: 12),
          if (llaves.length > 1)
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < llaves.length; i++)
                  ChoiceChip(
                    label: Text(llaves[i].label),
                    selected: i == index,
                    onSelected: (_) => setState(() => _selectedLlave = i),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          if (llave?.qrPayload != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                key: const Key('breb-qr'),
                data: llave!.qrPayload!,
                size: 230,
                backgroundColor: Colors.white,
              ),
            )
          else
            Text(
              'Esta llave no tiene QR configurado. El cliente paga escribiendo la llave y el valor exacto.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          if (llave != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: SelectableText(
                    'Llave: ${llave.llave}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar llave',
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => Clipboard.setData(ClipboardData(text: llave.llave)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
              Flexible(
                child: Obx(
                  () => Text(
                    'Esperando el pago… vence en ${_controller.remaining.value}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          TextButton(
            key: const Key('breb-received'),
            onPressed: _showReceivedPayments,
            child: const Text('¿Ya pagó y no se confirma? Ver pagos recibidos'),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('breb-cancel'),
              onPressed: _cancel,
              child: const Text('Cancelar cobro'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _message({required Widget icon, required String title, String? detail, List<Widget> actions = const []}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        icon,
        const SizedBox(height: 14),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        if (detail != null && detail.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(detail, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: actions),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _receivedButton() =>
      OutlinedButton(onPressed: _showReceivedPayments, child: const Text('Ver pagos recibidos'));

  /// Lista de pagos que llegaron y no se unieron solos; al tocar uno se asigna
  /// a este cobro.
  Future<void> _showReceivedPayments() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ReceivedPaymentsDialog(controller: _controller),
    );
  }

  Widget _closeButton() => TextButton(onPressed: () => _close(null), child: const Text('Cerrar'));

  Widget _retryButton() => FilledButton(onPressed: _start, child: const Text('Intentar de nuevo'));
}

/// Pagos Bre-B recibidos sin asignar; el cajero elige cuál es el de este cobro.
class _ReceivedPaymentsDialog extends StatefulWidget {
  final BrebPaymentController controller;
  const _ReceivedPaymentsDialog({required this.controller});

  @override
  State<_ReceivedPaymentsDialog> createState() => _ReceivedPaymentsDialogState();
}

class _ReceivedPaymentsDialogState extends State<_ReceivedPaymentsDialog> {
  List<BrebReceivedPayment>? _payments;
  String? _error;
  String? _assigningId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _payments = null;
      _error = null;
    });
    try {
      final payments = await widget.controller.receivedPayments();
      if (mounted) setState(() => _payments = payments);
    } on BrebException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudieron consultar los pagos recibidos.');
    }
  }

  Future<void> _assign(BrebReceivedPayment payment) async {
    setState(() {
      _assigningId = payment.id;
      _error = null;
    });
    final problem = await widget.controller.assignReceived(payment);
    if (!mounted) return;
    if (problem == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _assigningId = null;
      _error = problem;
    });
  }

  @override
  Widget build(BuildContext context) {
    final payments = _payments;
    return AlertDialog(
      title: const Text('Pagos Bre-B recibidos'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pagos que llegaron al banco en las últimas 24 horas y no se unieron solos a una venta. '
              'Toca el de este cliente para asignarlo.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, key: const Key('breb-assign-error'), style: TextStyle(color: Colors.red.shade700)),
              ),
            if (payments == null && _error == null)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (payments != null && payments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No hay pagos recibidos sin asignar.'),
              )
            else if (payments != null)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final payment in payments)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.payments_outlined),
                        title: Text(AppFormatters.formatCurrency(payment.amount)),
                        subtitle: Text([
                          if ((payment.payerName ?? '').isNotEmpty) payment.payerName,
                          if ((payment.bankLabel ?? '').isNotEmpty) payment.bankLabel,
                          if (payment.receivedAt != null) AppFormatters.formatDateTime(payment.receivedAt),
                        ].join(' · ')),
                        trailing: _assigningId == payment.id
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.chevron_right),
                        onTap: _assigningId == null ? () => _assign(payment) : null,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _assigningId == null ? _load : null, child: const Text('Actualizar')),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }
}
