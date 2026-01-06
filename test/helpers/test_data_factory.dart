// test/helpers/test_data_factory.dart

/// Factory class for generating test data
///
/// Provides common test data generators for entities, models, and ISAR objects
class TestDataFactory {
  /// Generates a unique ID with optional prefix
  static String generateId([String prefix = 'test']) {
    return '$prefix-${DateTime.now().millisecondsSinceEpoch}-${_counter++}';
  }

  static int _counter = 0;

  /// Generates a unique email
  static String generateEmail([String prefix = 'test']) {
    return '$prefix${_counter++}@example.com';
  }

  /// Generates a unique phone number
  static String generatePhone() {
    return '+1234567${(_counter++).toString().padLeft(4, '0')}';
  }

  /// Generates a unique SKU
  static String generateSku([String prefix = 'SKU']) {
    return '$prefix-${(_counter++).toString().padLeft(6, '0')}';
  }

  /// Generates a unique barcode
  static String generateBarcode() {
    return '${DateTime.now().millisecondsSinceEpoch}${_counter++}';
  }

  /// Generates a random price between min and max
  static double generatePrice({double min = 10.0, double max = 1000.0}) {
    return min + (max - min) * (_counter % 100) / 100;
  }

  /// Generates a random stock quantity
  static double generateStock({double min = 0.0, double max = 1000.0}) {
    return min + (max - min) * (_counter % 100) / 100;
  }

  /// Generates a test organization ID
  static String get organizationId => 'org-test-001';

  /// Generates a test user ID
  static String get userId => 'user-test-001';

  /// Generates a test tenant ID
  static String get tenantId => 'tenant-test-001';

  /// Resets the counter (useful between tests)
  static void reset() {
    _counter = 0;
  }

  /// Generates a list of test data using a generator function
  static List<T> generateList<T>(
    int count,
    T Function(int index) generator,
  ) {
    return List.generate(count, generator);
  }

  /// Generates a JSON payload for sync operations
  static String generateSyncPayload(
    String entityType,
    String entityId, {
    Map<String, dynamic>? additionalData,
  }) {
    final data = {
      'id': entityId,
      'entityType': entityType,
      'createdAt': DateTime.now().toIso8601String(),
      ...?additionalData,
    };

    return data.toString();
  }

  /// Generates a test date in the past
  static DateTime pastDate({int daysAgo = 7}) {
    return DateTime.now().subtract(Duration(days: daysAgo));
  }

  /// Generates a test date in the future
  static DateTime futureDate({int daysFromNow = 7}) {
    return DateTime.now().add(Duration(days: daysFromNow));
  }
}
