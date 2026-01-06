// test/mocks/mock_core.dart
import 'package:mocktail/mocktail.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import 'package:baudex_desktop/app/data/local/sync_service.dart';
import 'package:baudex_desktop/app/core/network/network_info.dart';

/// Mock classes for core services using mocktail
///
/// Mocktail doesn't require code generation - mocks are created on the fly

// Network mocks
class MockConnectivity extends Mock implements Connectivity {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

// HTTP mocks
class MockDio extends Mock implements Dio {}

class MockResponse<T> extends Mock implements Response<T> {}

class MockRequestOptions extends Mock implements RequestOptions {}

// Sync Service mock
class MockSyncService extends Mock implements SyncService {}
