// lib/app/core/printing/windows_raw_printer.dart
//
// Envía bytes RAW (ESC/POS) a una impresora instalada en Windows llamando
// directo a la cola de impresión (winspool: OpenPrinter → StartDocPrinter →
// WritePrinter), sin abrir PowerShell.
//
// Antes cada tiquete lanzaba `powershell` y compilaba una clase de C# con
// `Add-Type` para hacer estas mismas llamadas: eso cuesta segundos por
// tiquete. Aquí son las mismas llamadas del sistema, hechas desde la app,
// en un hilo aparte para no congelar la pantalla.
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class WindowsRawPrintException implements Exception {
  final String step;
  final int code;
  const WindowsRawPrintException(this.step, this.code);

  @override
  String toString() => 'La cola de impresión de Windows rechazó $step '
      '(código $code)';
}

/// Lanza [WindowsRawPrintException] si Windows no acepta el trabajo.
/// Solo se puede llamar en Windows.
Future<void> sendRawToWindowsPrinter(
  String printerName,
  Uint8List bytes, {
  String documentName = 'Baudex RAW Document',
}) =>
    Isolate.run(() => _sendRawSync(printerName, bytes, documentName));

void _sendRawSync(String printerName, Uint8List bytes, String documentName) {
  final pName = printerName.toNativeUtf16();
  final pDocName = documentName.toNativeUtf16();
  final pDataType = 'RAW'.toNativeUtf16();
  final phPrinter = calloc<IntPtr>();
  final docInfo = calloc<DOC_INFO_1>();
  final buffer = calloc<Uint8>(bytes.isEmpty ? 1 : bytes.length);
  final written = calloc<Uint32>();
  try {
    if (OpenPrinter(pName, phPrinter, nullptr) == 0) {
      throw WindowsRawPrintException('abrir la impresora', GetLastError());
    }
    final hPrinter = phPrinter.value;
    try {
      docInfo.ref
        ..pDocName = pDocName
        ..pOutputFile = nullptr
        ..pDatatype = pDataType;
      if (StartDocPrinter(hPrinter, 1, docInfo) == 0) {
        throw WindowsRawPrintException('iniciar el documento', GetLastError());
      }
      try {
        if (StartPagePrinter(hPrinter) == 0) {
          throw WindowsRawPrintException('iniciar la página', GetLastError());
        }
        buffer.asTypedList(bytes.length).setAll(0, bytes);
        final ok = WritePrinter(hPrinter, buffer, bytes.length, written);
        final error = ok == 0 ? GetLastError() : 0;
        EndPagePrinter(hPrinter);
        if (ok == 0) {
          throw WindowsRawPrintException('escribir el tiquete', error);
        }
        if (written.value != bytes.length) {
          throw WindowsRawPrintException(
              'escribir el tiquete completo (${written.value} de '
              '${bytes.length} bytes)',
              0);
        }
      } finally {
        EndDocPrinter(hPrinter);
      }
    } finally {
      ClosePrinter(hPrinter);
    }
  } finally {
    calloc.free(pName);
    calloc.free(pDocName);
    calloc.free(pDataType);
    calloc.free(phPrinter);
    calloc.free(docInfo);
    calloc.free(buffer);
    calloc.free(written);
  }
}
