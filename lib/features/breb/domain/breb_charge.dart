// lib/features/breb/domain/breb_charge.dart
//
// Cobro por Bre-B con QR (igual que en La Bomba): la venta viaja al servidor
// como borrador, el cliente escanea el QR y la factura se crea, ya pagada,
// cuando llega el aviso del banco.

/// Estado de un cobro según el servidor.
enum BrebChargeStatus {
  /// Esperando el aviso del banco.
  pending,

  /// El banco avisó y la venta quedó registrada y pagada.
  matched,

  /// Pasó el tiempo y el aviso no llegó.
  expired,

  /// El cajero lo canceló.
  cancelled,
}

BrebChargeStatus parseBrebStatus(dynamic raw) {
  switch (raw?.toString()) {
    case 'matched':
      return BrebChargeStatus.matched;
    case 'expired':
      return BrebChargeStatus.expired;
    case 'cancelled':
      return BrebChargeStatus.cancelled;
    default:
      // Incluye 'matching' (registrando el pago): para la app sigue esperando.
      return BrebChargeStatus.pending;
  }
}

/// Una llave Bre-B del negocio con su QR ya armado para este cobro.
class BrebLlaveQr {
  final String id;
  final String label;
  final String llave;

  /// Texto del QR con el monto del cobro; `null` si esa llave no tiene
  /// plantilla de QR (el cliente paga escribiendo la llave).
  final String? qrPayload;

  const BrebLlaveQr({
    required this.id,
    required this.label,
    required this.llave,
    this.qrPayload,
  });

  factory BrebLlaveQr.fromJson(Map<String, dynamic> json) => BrebLlaveQr(
        id: json['id']?.toString() ?? '',
        label: json['label']?.toString() ?? 'Llave',
        llave: json['llave']?.toString() ?? '',
        qrPayload: (json['qrPayload'] as String?)?.isNotEmpty == true
            ? json['qrPayload'] as String
            : null,
      );
}

/// Un cobro recién creado: lo que el cajero le muestra al cliente.
class BrebCharge {
  final String chargeId;

  /// Lo que el cliente debe transferir (único entre los cobros pendientes).
  final double amount;

  /// Lo que vale la venta; [amount] puede ser unos pesos menor.
  final double requestedAmount;
  final List<BrebLlaveQr> llaves;
  final DateTime expiresAt;

  const BrebCharge({
    required this.chargeId,
    required this.amount,
    required this.requestedAmount,
    required this.llaves,
    required this.expiresAt,
  });

  /// Pesos que se le bajaron al cobro para que su monto fuera único.
  double get adjustment => brebAdjustment(requestedAmount, amount);

  factory BrebCharge.fromJson(Map<String, dynamic> json) => BrebCharge(
        chargeId: json['chargeId'].toString(),
        amount: (json['amount'] as num).toDouble(),
        requestedAmount:
            ((json['requestedAmount'] ?? json['amount']) as num).toDouble(),
        llaves: ((json['llaves'] as List?) ?? const [])
            .map((l) => BrebLlaveQr.fromJson(Map<String, dynamic>.from(l as Map)))
            .where((l) => l.llave.isNotEmpty)
            .toList(),
        expiresAt:
            DateTime.tryParse(json['expiresAt']?.toString() ?? '')?.toLocal() ??
                DateTime.now().add(const Duration(minutes: 10)),
      );
}

/// Lo que responde el servidor cuando la app pregunta por el cobro.
class BrebChargeState {
  final BrebChargeStatus status;

  /// La factura creada (o la que se estaba cobrando), cuando ya hay pago.
  final String? invoiceId;

  /// El crédito al que se abonó, si el cobro era de un crédito.
  final String? creditId;
  final String? payerName;
  final String? bankLabel;

  const BrebChargeState({
    required this.status,
    this.invoiceId,
    this.creditId,
    this.payerName,
    this.bankLabel,
  });

  factory BrebChargeState.fromJson(Map<String, dynamic> json) => BrebChargeState(
        status: parseBrebStatus(json['status']),
        invoiceId: json['invoiceId']?.toString(),
        creditId: json['creditId']?.toString(),
        payerName: json['payerName']?.toString(),
        bankLabel: json['bankLabel']?.toString(),
      );
}

/// Un pago que SÍ llegó al banco pero no se pudo unir solo a un cobro (el
/// cliente transfirió otro valor, o el aviso llegó después de vencer el
/// cobro). El cajero lo puede asignar a mano.
class BrebReceivedPayment {
  final String id;
  final double amount;
  final String? payerName;
  final String? bankLabel;
  final String? reference;
  final DateTime? receivedAt;

  const BrebReceivedPayment({
    required this.id,
    required this.amount,
    this.payerName,
    this.bankLabel,
    this.reference,
    this.receivedAt,
  });

  factory BrebReceivedPayment.fromJson(Map<String, dynamic> json) => BrebReceivedPayment(
        id: json['id'].toString(),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        payerName: json['payerName']?.toString(),
        bankLabel: json['bankLabel']?.toString(),
        reference: json['reference']?.toString(),
        receivedAt: DateTime.tryParse(json['receivedAt']?.toString() ?? '')?.toLocal(),
      );
}

/// Diferencia entre lo que vale la venta y lo que se cobra (nunca negativa).
double brebAdjustment(double requested, double charged) {
  final d = ((requested - charged) * 100).round() / 100;
  return d > 0 ? d : 0;
}

/// Tiempo que le queda al cobro, como "9:05". "0:00" si ya venció.
String brebRemainingLabel(DateTime expiresAt, DateTime now) {
  final left = expiresAt.difference(now);
  if (left.isNegative) return '0:00';
  final minutes = left.inMinutes;
  final seconds = left.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// Llaves Bre-B guardadas en la configuración del negocio
/// (`settings.breb.llaves`), listas para editar.
List<Map<String, dynamic>> brebLlavesOf(Map<String, dynamic>? settings) {
  // Tolerante: una configuración con otro formato no debe tumbar la pantalla.
  final breb = settings?['breb'];
  final llaves = breb is Map ? breb['llaves'] : null;
  if (llaves is! List) return [];
  return llaves
      .whereType<Map>()
      .map((l) => Map<String, dynamic>.from(l))
      .where((l) => (l['llave']?.toString().trim() ?? '').isNotEmpty)
      .toList();
}

/// ¿El negocio puede cobrar por Bre-B? (tiene al menos una llave).
bool brebEnabled(Map<String, dynamic>? settings) =>
    brebLlavesOf(settings).isNotEmpty;

/// ¿Es un producto NO registrado? (el cajero escribió el valor y un nombre).
/// La app le pone un identificador temporal; el servidor lo guarda como
/// producto temporal de la factura. Misma regla del servidor.
bool isTemporaryProductId(String? id) =>
    id != null && (id.startsWith('temp_') || id.startsWith('unregistered_'));
