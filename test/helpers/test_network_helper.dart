// test/helpers/test_network_helper.dart
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mockito/mockito.dart';

/// Mock class for Connectivity
class MockConnectivity extends Mock implements Connectivity {}

/// Helper class for simulating network states in tests
///
/// Usage:
/// ```dart
/// void main() {
///   late NetworkSimulator networkSimulator;
///   late MockConnectivity mockConnectivity;
///
///   setUp(() {
///     mockConnectivity = MockConnectivity();
///     networkSimulator = NetworkSimulator(mockConnectivity);
///   });
///
///   tearDown(() {
///     networkSimulator.dispose();
///   });
///
///   test('test online behavior', () async {
///     networkSimulator.goOnline();
///     // ... test online logic
///   });
///
///   test('test offline behavior', () async {
///     networkSimulator.goOffline();
///     // ... test offline logic
///   });
/// }
/// ```
class NetworkSimulator {
  final MockConnectivity connectivity;
  final StreamController<List<ConnectivityResult>> _controller;

  NetworkSimulator(this.connectivity)
      : _controller =
            StreamController<List<ConnectivityResult>>.broadcast() {
    // Setup initial mock behavior
    when(connectivity.onConnectivityChanged)
        .thenAnswer((_) => _controller.stream);
  }

  /// Simulates WiFi connection (online)
  void goOnline({ConnectivityResult connectionType = ConnectivityResult.wifi}) {
    when(connectivity.checkConnectivity())
        .thenAnswer((_) async => [connectionType]);
    _controller.add([connectionType]);
  }

  /// Simulates no connection (offline)
  void goOffline() {
    when(connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.none]);
    _controller.add([ConnectivityResult.none]);
  }

  /// Simulates mobile data connection
  void goOnlineMobile() {
    goOnline(connectionType: ConnectivityResult.mobile);
  }

  /// Simulates ethernet connection
  void goOnlineEthernet() {
    goOnline(connectionType: ConnectivityResult.ethernet);
  }

  /// Simulates network error/exception
  void simulateNetworkError([String message = 'Network unreachable']) {
    when(connectivity.checkConnectivity())
        .thenThrow(SocketException(message));
  }

  /// Simulates timeout error
  void simulateTimeout() {
    when(connectivity.checkConnectivity())
        .thenThrow(TimeoutException('Connection timeout'));
  }

  /// Simulates rapid connection changes (WiFi on/off repeatedly)
  ///
  /// Useful for testing rapid network state changes
  void simulateRapidChanges(int count, {Duration interval = const Duration(milliseconds: 100)}) {
    var isOnline = false;
    Timer.periodic(interval, (timer) {
      if (timer.tick > count) {
        timer.cancel();
        return;
      }

      isOnline = !isOnline;
      if (isOnline) {
        goOnline();
      } else {
        goOffline();
      }
    });
  }

  /// Manually trigger a connectivity change event
  void emitConnectivityChange(List<ConnectivityResult> results) {
    _controller.add(results);
  }

  /// Dispose resources
  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}

/// Helper class for mocking NetworkInfo behavior
///
/// NetworkInfo is the app's abstraction over connectivity checking
class MockNetworkInfo {
  bool _isConnected = true;

  /// Set the connection state
  void setConnected(bool connected) {
    _isConnected = connected;
  }

  /// Check if connected
  Future<bool> get isConnected async => _isConnected;

  /// Simulate going online
  void goOnline() => setConnected(true);

  /// Simulate going offline
  void goOffline() => setConnected(false);
}
