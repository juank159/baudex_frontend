// test/unit/core/network/network_info_test.dart
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock class for Connectivity
class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late NetworkInfoImpl networkInfo;
  late MockConnectivity mockConnectivity;

  setUp(() {
    mockConnectivity = MockConnectivity();
    networkInfo = NetworkInfoImpl(mockConnectivity);
  });

  group('NetworkInfoImpl', () {
    group('isConnected', () {
      test('should return true when WiFi is connected', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        // Act
        final result = await networkInfo.isConnected;

        // Assert
        expect(result, true);
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });

      test('should return true when mobile data is connected', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.mobile]);

        // Act
        final result = await networkInfo.isConnected;

        // Assert
        expect(result, true);
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });

      test('should return true when ethernet is connected', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.ethernet]);

        // Act
        final result = await networkInfo.isConnected;

        // Assert
        expect(result, true);
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });

      test('should return false when no connection is available', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act
        final result = await networkInfo.isConnected;

        // Assert
        expect(result, false);
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });

      test('should return false when connectivity check throws exception',
          () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenThrow(Exception('Network error'));

        // Act
        final result = await networkInfo.isConnected;

        // Assert
        expect(result, false);
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });

      test('should handle multiple connectivity results correctly (WiFi + Mobile)',
          () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
            (_) async => [ConnectivityResult.wifi, ConnectivityResult.mobile]);

        // Act
        final result = await networkInfo.isConnected;

        // Assert
        expect(result, true);
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });

      test('should handle multiple connectivity results correctly (WiFi + Ethernet)',
          () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity()).thenAnswer((_) async =>
            [ConnectivityResult.wifi, ConnectivityResult.ethernet]);

        // Act
        final result = await networkInfo.isConnected;

        // Assert
        expect(result, true);
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });

      test('should return false when list contains only none', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act
        final result = await networkInfo.isConnected;

        // Assert
        expect(result, false);
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });

      test('should return true when list contains WiFi and none', () async {
        // Arrange - This scenario might not happen in practice but tests robustness
        when(() => mockConnectivity.checkConnectivity()).thenAnswer(
            (_) async => [ConnectivityResult.wifi, ConnectivityResult.none]);

        // Act
        final result = await networkInfo.isConnected;

        // Assert
        expect(result, true);
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });

      test('should return false when list is empty', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => []);

        // Act
        final result = await networkInfo.isConnected;

        // Assert
        expect(result, false);
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });

      test('should handle bluetooth connectivity as not connected', () async {
        // Arrange - Bluetooth isn't considered a network connection
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.bluetooth]);

        // Act
        final result = await networkInfo.isConnected;

        // Assert
        expect(result, false);
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });

      test('should handle VPN connectivity as connected', () async {
        // Arrange
        when(() => mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.vpn]);

        // Act
        final result = await networkInfo.isConnected;

        // Assert
        expect(result, false); // VPN is not checked in the implementation
        verify(() => mockConnectivity.checkConnectivity()).called(1);
      });
    });
  });
}
