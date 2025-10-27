import 'package:drift/drift.dart';
import '../app_database.dart';

class CategoryDao {
  final AppDatabase db;
  CategoryDao(this.db);

  Stream<List<Category>> watchAll() {
    final q = (db.select(db.categories)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.name),
      ]));
    return q.watch();
  }

  Future<List<Category>> allOnce() {
    final q = (db.select(db.categories)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.name),
      ]));
    return q.get();
  }

  Stream<List<Reminder>> watchRemindersByCategoryId(int categoryId) {
    final q = (db.select(db.reminders)
      ..where((t) => t.categoryId.equals(categoryId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.asc(t.scheduledAt),
        (t) => OrderingTerm.asc(t.title),
      ]));
    return q.watch();
  }

    Stream<Category?> watchById(int id) {
    final q = (db.select(db.categories)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull()));
    return q.watchSingleOrNull();
  }

  Future<int> insert(CategoriesCompanion data) =>
      db.into(db.categories).insert(data);

  Future<int> update({
    required int id,
    required String name,
    required String colorHex,
    int? sortOrder,
  }) {
    return (db.update(db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(name),
        colorHex: Value(colorHex),
        sortOrder: sortOrder == null ? const Value.absent() : Value(sortOrder),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteSoft(int id) {
    return (db.update(db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
