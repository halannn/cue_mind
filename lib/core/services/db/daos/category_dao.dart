import 'package:drift/drift.dart';
import '../app_database.dart';

class CategoryDao {
  final AppDatabase db;
  CategoryDao(this.db);

  // Stream agar UI auto-refresh
  Stream<List<Category>> watchAll() {
    final q = (db.select(db.categories)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.name)]));
    return q.watch();
  }

  Future<List<Category>> allOnce() {
    final q = (db.select(db.categories)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.name)]));
    return q.get();
  }

  Future<int> insert(CategoriesCompanion data) =>
      db.into(db.categories).insert(data);

  Future<int> updateNameAndColor({
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

  // Soft delete
  Future<int> deleteSoft(int id) {
    return (db.update(db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
