import 'package:connectivity_plus/connectivity_plus.dart'; // Importa este paquete

/// Contrato para verificar conexión a internet
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Implementación de NetworkInfo usando connectivity_plus
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity; // Inyecta la instancia de Connectivity

  // Constructor que recibe la instancia de Connectivity
  NetworkInfoImpl(this._connectivity);

  @override
  Future<bool> get isConnected async {
    // Obtiene el resultado de la conectividad actual
    final connectivityResult = await _connectivity.checkConnectivity();

    // Verifica si la lista de resultados contiene Wi-Fi o conexión móvil
    // Esto es más confiable que InternetAddress.lookup en algunos escenarios
    return connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(
          ConnectivityResult.ethernet,
        ); // Opcional: considerar Ethernet
  }

  // Puedes mantener los otros métodos si los usas en otras partes de tu app,
  // pero para la verificación de conectividad general es mejor usar el enfoque de connectivity_plus.
  // Si estos métodos también causan ANRs en otros lugares, considera reemplazarlos
  // o envolverlos en compute para ejecutar en un isolate si son muy lentos.

  // /// Verificar conexión con timeout personalizado (ejemplo, si aún lo necesitas)
  // Future<bool> hasConnectionWithTimeout({
  //   Duration timeout = const Duration(seconds: 5),
  // }) async {
  //   try {
  //     // Podrías usar este si necesitas una verificación más profunda a un host específico
  //     // y quieres el timeout, pero para 'isConnected' se prefiere connectivity_plus
  //     final result = await InternetAddress.lookup('google.com').timeout(timeout);
  //     return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  //   } on SocketException catch (_) {
  //     return false;
  //   } catch (_) {
  //     return false;
  //   }
  // }

  // /// Verificar conexión a un host específico (ejemplo, si aún lo necesitas)
  // Future<bool> canReachHost(
  //   String host, {
  //   Duration timeout = const Duration(seconds: 5),
  // }) async {
  //   try {
  //     final result = await InternetAddress.lookup(host).timeout(timeout);
  //     return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  //   } on SocketException catch (_) {
  //     return false;
  //   } catch (_) {
  //     return false;
  //   }
  // }
}
