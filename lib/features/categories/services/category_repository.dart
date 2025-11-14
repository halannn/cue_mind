import 'package:drift/drift.dart';
import '../../../core/services/db/app_database.dart';
import '../../../core/services/db/daos/category_dao.dart';

export '../../../core/services/db/app_database.dart' show Category, Reminder;

class CategoryRepository {
  final CategoryDao dao;
  CategoryRepository(this.dao);

  Stream<List<Category>> watchAll() => dao.watchAll();
  Future<List<Category>> allOnce() => dao.allOnce();
  Stream<List<Reminder>> watchRemindersByCategoryId(int categoryId) =>
      dao.watchRemindersByCategoryId(categoryId);
  Stream<Category?> watchById(int id) => dao.watchById(id);

  Future<int> create({
    required String name,
    String colorHex = '#8E8E93',
    int sortOrder = 0,
  }) {
    return dao.insert(
      CategoriesCompanion.insert(
        name: name,
        colorHex: Value(colorHex),
        sortOrder: Value(sortOrder),
      ),
    );
  }

  Future<int> update({
    required int id,
    required String name,
    required String colorHex,
    int? sortOrder,
  }) {
    return dao.update(
      id: id,
      name: name,
      colorHex: colorHex,
      sortOrder: sortOrder,
    );
  }

  Future<int> deleteSoft(int id) => dao.deleteSoft(id);

  Future<bool> nameExists(String name, {int? excludeId}) async {
    final all = await allOnce();
    return all.any(
      (cat) =>
          cat.name.toLowerCase() == name.trim().toLowerCase() &&
          cat.id != excludeId,
    );
  }
}
