import 'package:flutter_test/flutter_test.dart';
import 'package:cue_mind/core/services/db/app_database.dart';
import 'package:cue_mind/core/services/db/daos/category_dao.dart';
import 'package:cue_mind/features/categories/services/category_repository.dart';

// Manual mock for testing
class MockCategoryDao implements CategoryDao {
  int insertCallCount = 0;
  int updateCallCount = 0;
  int deleteSoftCallCount = 0;
  int watchAllCallCount = 0;
  int allOnceCallCount = 0;

  List<Category> mockCategories = [];

  @override
  Future<int> insert(CategoriesCompanion data) async {
    insertCallCount++;
    return mockCategories.length + 1;
  }

  @override
  Future<int> update({
    required int id,
    required String name,
    required String colorHex,
    int? sortOrder,
  }) async {
    updateCallCount++;
    return 1;
  }

  @override
  Future<int> deleteSoft(int id) async {
    deleteSoftCallCount++;
    return 1;
  }

  @override
  Stream<List<Category>> watchAll() {
    watchAllCallCount++;
    return Stream.value(mockCategories);
  }

  @override
  Future<List<Category>> allOnce() async {
    allOnceCallCount++;
    return mockCategories;
  }

  @override
  Stream<List<Reminder>> watchRemindersByCategoryId(int categoryId) {
    return Stream.value([]);
  }

  @override
  Stream<Category?> watchById(int id) {
    return Stream.value(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Category Repository Tests', () {
    late MockCategoryDao mockDao;
    late CategoryRepository repository;

    setUp(() {
      // Arrange - Initialize mock and repository
      mockDao = MockCategoryDao();
      repository = CategoryRepository(mockDao);
    });

    test('should create category with default color and sort order', () async {
      // Arrange
      const categoryName = 'Work';

      // Act
      final result = await repository.create(name: categoryName);

      // Assert
      expect(result, 1);
      expect(mockDao.insertCallCount, 1);
    });

    test('should create category with custom color and sort order', () async {
      // Arrange
      const categoryName = 'Personal';
      const colorHex = '#FF5733';
      const sortOrder = 5;

      // Act
      final result = await repository.create(
        name: categoryName,
        colorHex: colorHex,
        sortOrder: sortOrder,
      );

      // Assert
      expect(result, 1);
      expect(mockDao.insertCallCount, 1);
    });

    test('should update category name and color successfully', () async {
      // Arrange
      const categoryId = 3;
      const newName = 'Updated Category';
      const newColorHex = '#00FF00';

      // Act
      final result = await repository.update(
        id: categoryId,
        name: newName,
        colorHex: newColorHex,
      );

      // Assert
      expect(result, 1);
      expect(mockDao.updateCallCount, 1);
    });

    test('should update category including sort order parameter', () async {
      // Arrange
      const categoryId = 4;
      const newName = 'Priority Category';
      const newColorHex = '#FF0000';
      const newSortOrder = 10;

      // Act
      final result = await repository.update(
        id: categoryId,
        name: newName,
        colorHex: newColorHex,
        sortOrder: newSortOrder,
      );

      // Assert
      expect(result, 1);
      expect(mockDao.updateCallCount, 1);
    });

    test('should perform soft delete on category successfully', () async {
      // Arrange
      const categoryId = 5;

      // Act
      final result = await repository.deleteSoft(categoryId);

      // Assert
      expect(result, 1);
      expect(mockDao.deleteSoftCallCount, 1);
    });

    test('should return true when category name exists in database', () async {
      // Arrange
      const existingName = 'Work';
      mockDao.mockCategories = [
        Category(
          id: 1,
          name: 'Work',
          colorHex: '#8E8E93',
          sortOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deletedAt: null,
        ),
        Category(
          id: 2,
          name: 'Personal',
          colorHex: '#8E8E93',
          sortOrder: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deletedAt: null,
        ),
      ];

      // Act
      final result = await repository.nameExists(existingName);

      // Assert
      expect(result, true);
      expect(mockDao.allOnceCallCount, 1);
    });

    test('should return false when category name does not exist', () async {
      // Arrange
      const newName = 'Shopping';
      mockDao.mockCategories = [
        Category(
          id: 1,
          name: 'Work',
          colorHex: '#8E8E93',
          sortOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deletedAt: null,
        ),
      ];

      // Act
      final result = await repository.nameExists(newName);

      // Assert
      expect(result, false);
      expect(mockDao.allOnceCallCount, 1);
    });

    test('should exclude specified category id when checking name uniqueness', () async {
      // Arrange
      const categoryId = 1;
      const categoryName = 'Work';
      mockDao.mockCategories = [
        Category(
          id: 1,
          name: 'Work',
          colorHex: '#8E8E93',
          sortOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deletedAt: null,
        ),
      ];

      // Act
      final result = await repository.nameExists(categoryName, excludeId: categoryId);

      // Assert
      expect(result, false);
      expect(mockDao.allOnceCallCount, 1);
    });

    test('should return stream when watching all categories', () {
      // Arrange & Act
      final result = repository.watchAll();

      // Assert
      expect(result, isA<Stream<List<Category>>>());
      expect(mockDao.watchAllCallCount, 1);
    });

    test('should fetch all categories in single operation', () async {
      // Arrange
      mockDao.mockCategories = [
        Category(
          id: 1,
          name: 'Work',
          colorHex: '#8E8E93',
          sortOrder: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deletedAt: null,
        ),
      ];

      // Act
      final result = await repository.allOnce();

      // Assert
      expect(result, mockDao.mockCategories);
      expect(mockDao.allOnceCallCount, 1);
    });
  });
}
