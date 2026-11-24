// lib/app/core/printing/network_raw_sender.dart
//
// Envía un tiquete ya armado a una impresora de red (puerto RAW, 9100) en
// una sola conexión: conectar → escribir todo → vaciar → cerrar.
//
// Antes se abría la conexión, se escribía bloque por bloque con pausas
// fijas (50 + 100 + 200 ms) y se cortaba con `destroy()`; las pausas eran
// la única garantía de que el papel alcanzara a recibir los datos. Aquí la
// garantía es `flush()` + cierre ordenado, y no hay ninguna pausa fija.
import 'dart:async';
import 'dart:io';

/// La impresora no respondió o rechazó la conexión.
class NetworkPrinterException implements Exception {
  final String message;
  final bool timedOut;
  const NetworkPrinterException(this.message, {this.timedOut = false});

  @override
  String toString() => message;
}

/// Devuelve cuando todos los bytes quedaron entregados al sistema para su
/// envío. El cierre de la conexión termina en segundo plano.
Future<void> sendBytesToNetworkPrinter(
  String host,
  int port,
  List<int> bytes, {
  Duration connectTimeout = const Duration(seconds: 5),
  Duration sendTimeout = const Duration(seconds: 10),
}) async {
  final Socket socket;
  try {
    socket = await Socket.connect(host, port, timeout: connectTimeout);
  } on SocketException catch (e) {
    final timedOut = e.message.toLowerCase().contains('timed out');
    throw NetworkPrinterException(
      timedOut
          ? 'La impresora no responde en $host:$port'
          : 'No se pudo conectar con la impresora en $host:$port',
      timedOut: timedOut,
    );
  }

  // Lo que la impresora conteste se descarta: si quedara sin leer, el
  // sistema podría cortar la conexión de golpe y perder el final del tiquete.
  final peerClosed = Completer<void>();
  final sub = socket.listen(
    (_) {},
    onError: (_) {
      if (!peerClosed.isCompleted) peerClosed.complete();
    },
    onDone: () {
      if (!peerClosed.isCompleted) peerClosed.complete();
    },
    cancelOnError: true,
  );

  try {
    try {
      socket.setOption(SocketOption.tcpNoDelay, true);
    } catch (_) {}
    socket.add(bytes);
    await socket.flush().timeout(sendTimeout);
  } catch (e) {
    await sub.cancel();
    socket.destroy();
    throw NetworkPrinterException(
      'Se cortó el envío a la impresora en $host:$port',
      timedOut: e is TimeoutException,
    );
  }

  // Cierre ordenado sin hacer esperar a quien imprime.
  unawaited(() async {
    try {
      await socket.close().timeout(sendTimeout);
      await peerClosed.future.timeout(const Duration(seconds: 2));
    } catch (_) {
    } finally {
      await sub.cancel();
      socket.destroy();
    }
  }());
}
