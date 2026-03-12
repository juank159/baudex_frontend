// test/e2e/offline_first/category_online_offline_online_test.dart
import 'package:baudex_desktop/app/core/network/network_info.dart';
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/app/data/local/isar_database.dart';
import 'package:baudex_desktop/features/categories/data/datasources/category_local_datasource.dart';
import 'package:baudex_desktop/features/categories/data/datasources/category_remote_datasource.dart';
import 'package:baudex_desktop/features/categories/data/models/isar/isar_category.dart';
import 'package:baudex_desktop/features/categories/data/models/category_model.dart';
import 'package:baudex_desktop/features/categories/data/models/create_category_request_model.dart';
import 'package:baudex_desktop/features/categories/data/repositories/category_repository_impl.dart';
import 'package:baudex_desktop/features/categories/domain/entities/category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_isar.dart';
import '../../fixtures/category_fixtures.dart';

// Mocks
class MockCategoryRemoteDataSource extends Mock
    implements CategoryRemoteDataSource {}

class MockCategoryLocalDataSource extends Mock
    implements CategoryLocalDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

// Fake classes for mocktail fallback values
class FakeCreateCategoryRequestModel extends Fake
    implements CreateCategoryRequestModel {}

class FakeCategoryModel extends Fake implements CategoryModel {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeCreateCategoryRequestModel());
    registerFallbackValue(FakeCategoryModel());
  });

  late CategoryRepositoryImpl repository;
  late MockCategoryLocalDataSource mockLocalDataSource;
  late MockCategoryRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late MockIsar mockIsar;
  late MockIsarDatabase mockIsarDatabase;

  setUp(() {
    mockIsar = MockIsar();
    mockIsarDatabase = MockIsarDatabase(mockIsar);
    mockLocalDataSource = MockCategoryLocalDataSource();
    mockRemoteDataSource = MockCategoryRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();

    repository = CategoryRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
      database: mockIsarDatabase,
    );
  });

  tearDown(() async {
    await mockIsar.clear();
    await mockIsar.close();
  });

  group('Category E2E: Online → Offline → Online', () {
    test(
      'complete flow: online create → offline read → online sync',
      () async {
        // ========== PHASE 1: ONLINE - Create Category ==========
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final tCategory = CategoryFixtures.createCategoryEntity();
        final tCategoryModel = CategoryModel.fromEntity(tCategory);

        when(() => mockRemoteDataSource.createCategory(any()))
            .thenAnswer((_) async => tCategoryModel);
        when(() => mockLocalDataSource.cacheCategory(any()))
            .thenAnswer((_) async => {});

        final createResult = await repository.createCategory(
          name: tCategory.name,
          slug: tCategory.slug,
          description: tCategory.description,
        );

        expect(createResult.isRight(), true);

        String? categoryId;
        createResult.fold(
          (failure) => fail('Online create should succeed'),
          (category) {
            categoryId = category.id;
            expect(category.name, tCategory.name);
          },
        );

        // Verify cached locally
        verify(() => mockLocalDataSource.cacheCategory(any())).called(1);

        // Add category to ISAR for offline operations
        final isarCategory = IsarCategory.fromEntity(tCategory);
        await mockIsar.writeTxn(() async {
          await mockIsar.isarCategorys.put(isarCategory);
        });

        // ========== PHASE 2: OFFLINE - Read Category ==========
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.getCachedCategory(any()))
            .thenAnswer((_) async => tCategoryModel);

        final offlineReadResult = await repository.getCategoryById(categoryId!);

        expect(offlineReadResult.isRight(), true);
        offlineReadResult.fold(
          (failure) => fail('Offline read should succeed from cache'),
          (category) {
            expect(category.id, categoryId);
            expect(category.name, tCategory.name);
          },
        );

        // ========== PHASE 3: OFFLINE - Update Category ==========
        final updatedCategory = CategoryFixtures.createCategoryEntity(
          id: categoryId!,
          name: 'Updated Offline',
        );
        final updatedCategoryModel = CategoryModel.fromEntity(updatedCategory);

        when(() => mockLocalDataSource.getCachedCategory(any()))
            .thenAnswer((_) async => tCategoryModel);
        when(() => mockLocalDataSource.cacheCategory(any()))
            .thenAnswer((_) async => {});

        final offlineUpdateResult = await repository.updateCategory(
          id: categoryId!,
          name: 'Updated Offline',
        );

        expect(offlineUpdateResult.isRight(), true);

        // Verify marked as unsynced
        final updatedCachedCategory = await mockIsar.isarCategorys
            .filter()
            .serverIdEqualTo(categoryId!)
            .findFirst();

        expect(updatedCachedCategory!.isSynced, false);
        expect(updatedCachedCategory.name, 'Updated Offline');

        // ========== PHASE 4: ONLINE AGAIN - Sync Changes ==========
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        when(() => mockRemoteDataSource.getCategoryById(any()))
            .thenAnswer((_) async => updatedCategoryModel);
        when(() => mockLocalDataSource.cacheCategory(any()))
            .thenAnswer((_) async => {});

        final onlineReadResult = await repository.getCategoryById(categoryId!);

        expect(onlineReadResult.isRight(), true);
        onlineReadResult.fold(
          (failure) => fail('Online read should succeed'),
          (category) {
            expect(category.name, 'Updated Offline');
          },
        );
      },
    );

    test(
      'offline category creation then online sync with server ID replacement',
      () async {
        // ========== PHASE 1: OFFLINE - Create Category ==========
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(() => mockLocalDataSource.cacheCategory(any()))
            .thenAnswer((_) async => {});

        // Create category offline
        final offlineCreateResult = await repository.createCategory(
          name: 'Offline Created Category',
          slug: 'offline-created-category',
          description: 'Created while offline',
        );

        expect(offlineCreateResult.isRight(), true);

        String? offlineId;
        offlineCreateResult.fold(
          (failure) => fail('Offline create should succeed'),
          (category) {
            offlineId = category.id;
            expect(category.id.startsWith('cat'), true);
            expect(category.name, 'Offline Created Category');
          },
        );

        // Verify cached with offline ID
        verify(() => mockLocalDataSource.cacheCategory(any())).called(1);

        // ========== PHASE 2: ONLINE - Sync with Server ==========
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        // Simulate server assigning real ID
        final serverCategory = CategoryModel.fromEntity(
          CategoryFixtures.createCategoryEntity(
            id: 'cat-server-456',
            name: 'Offline Created Category',
            slug: 'offline-created-category',
            description: 'Created while offline',
          ),
        );

        when(() => mockRemoteDataSource.getCategoryById(any()))
            .thenAnswer((_) async => serverCategory);
        when(() => mockLocalDataSource.getCachedCategory(any()))
            .thenAnswer((_) async => null);
        when(() => mockLocalDataSource.cacheCategory(any()))
            .thenAnswer((_) async => {});

        // Read with server ID would return the synced version
        final syncedResult = await repository.getCategoryById('cat-server-456');

        expect(syncedResult.isRight(), true);
        syncedResult.fold(
          (failure) => fail('Should get synced category'),
          (category) {
            expect(category.id, 'cat-server-456');
            expect(category.name, 'Offline Created Category');
          },
        );
      },
    );

    test(
      'network interruption during operation with graceful degradation',
      () async {
        // ========== PHASE 1: ONLINE - Initial State ==========
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final tCategory = CategoryFixtures.createCategoryEntity();
        final tCategoryModel = CategoryModel.fromEntity(tCategory);

        when(() => mockRemoteDataSource.createCategory(any()))
            .thenAnswer((_) async => tCategoryModel);
        when(() => mockLocalDataSource.cacheCategory(any()))
            .thenAnswer((_) async => {});

        await repository.createCategory(
          name: tCategory.name,
          slug: tCategory.slug,
          description: tCategory.description,
        );

        // ========== PHASE 2: NETWORK INTERRUPTION ==========
        // Simulate network failure during read
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(() => mockRemoteDataSource.getCategoryById(any()))
            .thenThrow(Exception('Network timeout'));
        when(() => mockLocalDataSource.getCachedCategory(any()))
            .thenAnswer((_) async => tCategoryModel);

        // Should fallback to cache gracefully
        final result = await repository.getCategoryById(tCategory.id);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should fallback to cache'),
          (category) => expect(category.id, tCategory.id),
        );

        // Verify fallback was used
        verify(() => mockRemoteDataSource.getCategoryById(any())).called(1);
        verify(() => mockLocalDataSource.getCachedCategory(any())).called(1);
      },
    );
  });
}
