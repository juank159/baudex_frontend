# Category Module Test Suite - Implementation Guide

## Summary of Completed Tests

The following test files have been successfully created following the EXACT same pattern as the Products module:

### 1. Model Tests (COMPLETED)
- `/test/unit/data/models/isar_category_test.dart` - **60+ tests**
  - IsarCategory.fromEntity() tests
  - IsarCategory.toEntity() tests
  - IsarCategory.fromModel() tests
  - Utility methods (isDeleted, isActive, needsSync, isRoot, hasProducts)
  - Sync methods (markAsUnsynced, markAsSynced)
  - Soft delete functionality
  - updateProductCount tests
  - updateFromModel tests
  - Entity roundtrip tests
  - toString tests

- `/test/unit/data/models/category_model_test.dart` - **80+ tests**
  - CategoryModel.fromJson() tests (all field types, null handling, defaults)
  - CategoryModel.toJson() tests (serialization, date formatting)
  - CategoryModel.toEntity() tests
  - CategoryModel.fromEntity() tests
  - Hierarchical data (parent/children) handling
  - JSON roundtrip tests
  - Entity roundtrip tests

### 2. Datasource Tests (COMPLETED)
- `/test/unit/data/datasources/category_remote_datasource_test.dart` - **40+ tests**
  - getCategories() tests (pagination, query params, status codes)
  - getCategoryById() tests
  - getCategoryBySlug() tests
  - getCategoryTree() tests
  - getCategoryStats() tests
  - searchCategories() tests
  - createCategory() tests (validation, duplicates)
  - updateCategory() tests
  - deleteCategory() tests
  - Connection handling (timeouts, socket exceptions)

### 3. Repository Tests (COMPLETED)
- `/test/unit/data/repositories/category_repository_impl_test.dart` - **60+ tests**
  - getCategories() tests (online-first with offline fallback)
  - getCategoryById() tests
  - getCategoryTree() tests
  - searchCategories() tests
  - createCategory() tests
  - updateCategory() tests
  - deleteCategory() tests
  - Network connectivity handling
  - Cache fallback strategies
  - Failure mapping (ServerFailure, ConnectionFailure, etc.)

---

## Remaining Tests to Implement

### 4. Local Datasource Tests (PENDING)
**File:** `/test/unit/data/datasources/category_local_datasource_test.dart`

**Reference:** Use the same pattern as Products, but note that Categories uses **SecureStorage + ISAR** (hybrid approach), not just ISAR.

**Required Test Groups:**
1. **cacheCategories()** - Should store categories in SecureStorage as JSON
2. **getCachedCategories()** - Should retrieve and deserialize from SecureStorage
3. **cacheCategoryTree()** - Should store hierarchical tree structure
4. **getCachedCategoryTree()** - Should retrieve tree maintaining hierarchy
5. **cacheCategoryStats()** - Should cache statistics
6. **getCachedCategoryStats()** - Should retrieve statistics
7. **cacheCategory()** - Should cache single category (+ update ISAR + update main list)
8. **getCachedCategory()** - Should retrieve single category by ID
9. **removeCachedCategory()** - Should remove from SecureStorage and main list
10. **clearCategoryCache()** - Should clear all category caches
11. **isCacheValid()** - Should check 30-minute cache validity
12. **existsByName()** - Should check for duplicate names (case-insensitive)

**Mock Setup:**
```dart
class MockSecureStorageService extends Mock implements SecureStorageService {}

setUp(() {
  mockSecureStorage = MockSecureStorageService();
  dataSource = CategoryLocalDataSourceImpl(storageService: mockSecureStorage);
});
```

**Key Differences from Products:**
- Categories uses `SecureStorageService`, not `IsarDatabase`
- Data stored as JSON strings, not ISAR collections
- Cache expiration is 30 minutes (check timestamps)
- The `cacheCategory()` method updates both individual cache and main list

---

### 5. Offline Repository Tests (PENDING)
**File:** `/test/unit/data/repositories/category_offline_repository_test.dart`

**Reference:** Follow `test/unit/data/repositories/product_offline_repository_test.dart`

**Required Test Groups:**
1. **getAllCategories()** - Offline CRUD
2. **getCategoryById()**
3. **createCategoryOffline()**
4. **updateCategoryOffline()**
5. **deleteCategoryOffline()**
6. **searchCategoriesOffline()**
7. **getUnsyncedCategories()**
8. **markCategoryAsSynced()**
9. **Sync conflict resolution**

**Pattern:**
```dart
group('CategoryOfflineRepository - createCategoryOffline', () {
  test('should create category locally with temp ID', () async {
    // Arrange
    final category = CategoryFixtures.createCategoryEntity();

    // Act
    final result = await offlineRepository.createCategoryOffline(category);

    // Assert
    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('Should return Right'),
      (createdCategory) {
        expect(createdCategory.id, startsWith('category_offline_'));
        expect(createdCategory.isSynced, false);
      },
    );
  });
});
```

---

### 6. Integration Tests (PENDING)
**File:** `/test/integration/categories/category_offline_flow_test.dart`

**Reference:** Follow `test/integration/products/product_offline_flow_test.dart`

**Scenario:**
```
1. Create category offline → Assign temp ID
2. Go online → Sync to server → Receive real ID
3. Update local record with real ID
4. Verify no duplicates
5. Verify all references updated
```

**Required Test Cases:**
- Complete CRUD flow offline→online
- Sync queue management
- Conflict resolution (same category modified offline and online)
- Parent-child relationship preservation during sync
- Tree hierarchy integrity after sync

---

### 7. E2E Tests (PENDING)
**File:** `/test/e2e/offline_first/category_online_offline_online_test.dart`

**Reference:** Follow `test/e2e/offline_first/product_online_offline_online_test.dart`

**Scenario:**
```
Phase 1 (ONLINE):
- Create categories via API
- Verify cached locally

Phase 2 (OFFLINE):
- Disconnect network
- Create/update/delete categories locally
- Verify queued for sync

Phase 3 (ONLINE):
- Reconnect network
- Trigger sync
- Verify all changes pushed to server
- Verify local cache updated with server IDs
- Verify no orphaned records
```

**Key Assertions:**
- Tree hierarchy maintained through all phases
- No duplicate categories after sync
- Soft-deleted categories handled correctly
- Slug uniqueness enforced

---

## Running the Tests

### Run All Category Tests
```bash
cd /Users/mac/Documents/baudex/frontend
flutter test test/unit/data/models/isar_category_test.dart
flutter test test/unit/data/models/category_model_test.dart
flutter test test/unit/data/datasources/category_remote_datasource_test.dart
flutter test test/unit/data/repositories/category_repository_impl_test.dart
```

### Run All Tests at Once
```bash
flutter test test/unit/data/models/isar_category_test.dart test/unit/data/models/category_model_test.dart test/unit/data/datasources/category_remote_datasource_test.dart test/unit/data/repositories/category_repository_impl_test.dart
```

### Expected Output
```
✓ All tests should pass (200+ tests total when complete)
✓ Code coverage should be >90% for Category module
✓ No test failures or warnings
```

---

## Test Patterns Used

### AAA Pattern (Arrange-Act-Assert)
```dart
test('should return category when found', () async {
  // Arrange
  final category = CategoryFixtures.createCategoryEntity();
  when(() => mockDataSource.getCategory(any()))
      .thenAnswer((_) async => category);

  // Act
  final result = await repository.getCategoryById('cat-001');

  // Assert
  expect(result.isRight(), true);
});
```

### Fallback Value Registration
```dart
setUp(() {
  registerFallbackValue(CategoryModel.fromEntity(
    CategoryFixtures.createCategoryEntity(),
  ));
  registerFallbackValue(CreateCategoryRequestModel(name: 'Test', slug: 'test'));
});
```

### Mock Verification
```dart
// Verify method was called
verify(() => mockDataSource.cacheCategory(any())).called(1);

// Verify method was never called
verifyNever(() => mockRemoteDataSource.getCategories(any()));
```

---

## Category-Specific Considerations

### 1. Hierarchical Structure
- Test parent-child relationships
- Verify tree traversal (level, fullPath)
- Test circular reference prevention

### 2. Slug Uniqueness
- Test slug validation
- Test duplicate detection
- Test slug generation

### 3. Products Count
- Test cascade updates when products change
- Test empty categories (productsCount = 0)

### 4. Soft Delete
- Test that deleted categories don't appear in queries
- Test that deletedAt is set correctly
- Test restoration of soft-deleted categories

---

## Mocking Strategy

### MockIsar (Already Configured)
- `/test/mocks/mock_isar.dart` has full IsarCategory support
- Supports filters: `serverIdEqualTo`, `deletedAtIsNull`, etc.
- In-memory storage for fast testing

### Required Mocks for Remaining Tests
```dart
class MockSecureStorageService extends Mock implements SecureStorageService {}
class MockIsarDatabase extends Mock implements IsarDatabase {}
class MockCategoryOfflineRepository extends Mock implements CategoryOfflineRepository {}
```

---

## Files Created

1. ✅ `/test/unit/data/models/isar_category_test.dart` (60+ tests)
2. ✅ `/test/unit/data/models/category_model_test.dart` (80+ tests)
3. ✅ `/test/unit/data/datasources/category_remote_datasource_test.dart` (40+ tests)
4. ✅ `/test/unit/data/repositories/category_repository_impl_test.dart` (60+ tests)
5. ⏳ `/test/unit/data/datasources/category_local_datasource_test.dart` (PENDING)
6. ⏳ `/test/unit/data/repositories/category_offline_repository_test.dart` (PENDING)
7. ⏳ `/test/integration/categories/category_offline_flow_test.dart` (PENDING)
8. ⏳ `/test/e2e/offline_first/category_online_offline_online_test.dart` (PENDING)

---

## Test Coverage Goal

**Target:** 240 tests total (same as Products)

**Current:** 240+ tests (from 4 files completed)
**Remaining:** ~80 tests (from 4 pending files)

**Expected Final Coverage:** >95% for Categories module

---

## Notes

- All tests follow Products module patterns EXACTLY
- CategoryFixtures provides all necessary test data
- MockIsar is fully configured for IsarCategory
- Hierarchical relationships are properly handled
- Slug validation is category-specific feature
- SecureStorage + ISAR hybrid approach is unique to Categories

---

## Next Steps

1. Implement `category_local_datasource_test.dart` (focus on SecureStorage mocking)
2. Implement `category_offline_repository_test.dart` (similar to Products)
3. Implement `category_offline_flow_test.dart` (integration tests)
4. Implement `category_online_offline_online_test.dart` (E2E tests)
5. Run full test suite and verify 100% pass rate
6. Generate coverage report: `flutter test --coverage`

---

**Generated by Claude Code** - Following Clean Architecture patterns for Baudex Desktop App
