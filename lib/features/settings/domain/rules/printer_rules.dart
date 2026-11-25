// lib/features/settings/domain/rules/printer_rules.dart
//
// Reglas de impresoras, sin Flutter ni GetX, para poder probarlas solas.
import '../entities/printer_settings.dart';

/// Código de Windows cuando se pide una impresora que no está instalada
/// en el equipo (ERROR_INVALID_PRINTER_NAME).
const int windowsInvalidPrinterName = 1801;

/// La impresora con la que este equipo imprime facturas y recibos.
///
/// Orden: la que se eligió en este equipo ([deviceChoiceId]) → la marcada
/// como predeterminada → la única que hay, o la primera por nombre.
/// Devuelve null solo si no hay ninguna impresora guardada.
///
/// La elección es por equipo: [deviceChoiceId] vive en las preferencias de
/// este computador y no se sincroniza.
PrinterSettings? pickBillingPrinter(
  List<PrinterSettings> printers, {
  String? deviceChoiceId,
}) {
  final usable = printers.where((p) => p.isActive).toList();
  final candidates = usable.isNotEmpty ? usable : printers;
  if (candidates.isEmpty) return null;

  if (deviceChoiceId != null && deviceChoiceId.isNotEmpty) {
    for (final p in candidates) {
      if (p.id == deviceChoiceId) return p;
    }
  }

  final sorted = [...candidates]..sort(
    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );
  for (final p in sorted) {
    if (p.isDefault) return p;
  }
  return sorted.first;
}

/// Un id que puso el servidor (UUID). Los creados sin internet son
/// `printer_offline_<milisegundos>`.
bool isServerPrinterId(String id) => RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
).hasMatch(id);

/// Qué hacer cuando el servidor falla al eliminar una impresora.
enum PrinterDeleteOutcome {
  /// Ya no existe en el servidor: se da por eliminada.
  alreadyGone,

  /// El servidor dijo que no: no se borra en este equipo.
  rejected,

  /// No se pudo hablar con el servidor: se borra aquí y queda en cola.
  retryLater,
}

/// [statusCode] es null cuando no hubo respuesta (sin red, tiempo agotado).
PrinterDeleteOutcome classifyPrinterDeleteFailure(int? statusCode) {
  if (statusCode == null) return PrinterDeleteOutcome.retryLater;
  if (statusCode == 404) return PrinterDeleteOutcome.alreadyGone;
  if (statusCode == 401 || statusCode == 408 || statusCode == 429) {
    return PrinterDeleteOutcome.retryLater;
  }
  if (statusCode >= 400 && statusCode < 500) {
    return PrinterDeleteOutcome.rejected;
  }
  return PrinterDeleteOutcome.retryLater;
}

/// El servidor no deja a este usuario guardar impresoras del negocio
/// (solo administradores y gerentes).
bool isPrinterPermissionDenied(int? statusCode) => statusCode == 403;

/// Motivo del rechazo, en palabras para un cajero.
String printerDeleteRejectionMessage(int? statusCode, String serverMessage) {
  if (statusCode == 403) {
    return 'No tienes permiso para eliminar impresoras. '
        'Pídele a un administrador que lo haga.';
  }
  final reason = cleanServerMessage(serverMessage);
  if (reason.isEmpty) return 'El servidor no permitió eliminar la impresora.';
  return 'El servidor no permitió eliminar la impresora: $reason';
}

/// Quita los prefijos técnicos que el cliente HTTP le pone a los mensajes.
String cleanServerMessage(String message) {
  var text = message.trim();
  const prefixes = [
    'Solicitud incorrecta:',
    'Recurso no encontrado:',
    'Conflicto:',
    'Error interno del servidor:',
    'Error:',
  ];
  for (final prefix in prefixes) {
    if (text.startsWith(prefix)) {
      text = text.substring(prefix.length).trim();
      break;
    }
  }
  return text;
}

/// Mensaje cuando Windows no pudo imprimir por USB. [nativeCode] es el
/// código que devolvió la cola de impresión de Windows, si lo hubo.
String windowsUsbFailureMessage(String printerName, {int? nativeCode}) {
  if (nativeCode == windowsInvalidPrinterName) {
    return 'La impresora "$printerName" no está instalada en este equipo. '
        'Ve a Configuración > Impresoras y elige la impresora de este equipo.';
  }
  return 'No se pudo imprimir en "$printerName". Revisa que esté encendida '
      'y conectada.';
}
