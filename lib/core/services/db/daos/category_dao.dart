import 'package:drift/drift.dart';
import '../app_database.dart';

class CategoryDao {
  final AppDatabase db;
  CategoryDao(this.db);

  Stream<List<Category>> watchAll() {
    final q = (db.select(db.categories)
      ..where((t) => t.deletedAt.isNull() & t.isArchived.equals(false))
      ..orderBy([
        (t) => OrderingTerm.desc(t.isPinned),
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.name),
      ]));
    return q.watch();
  }

  Future<List<Category>> allOnce() {
    final q = (db.select(db.categories)
      ..where((t) => t.deletedAt.isNull() & t.isArchived.equals(false))
      ..orderBy([
        (t) => OrderingTerm.desc(t.isPinned),
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.name),
      ]));
    return q.get();
  }

  Stream<List<Category>> watchArchived() {
    final q = (db.select(db.categories)
      ..where((t) => t.deletedAt.isNull() & t.isArchived.equals(true))
      ..orderBy([
        (t) => OrderingTerm.desc(t.updatedAt),
        (t) => OrderingTerm.asc(t.name),
      ]));
    return q.watch();
  }

  Future<List<Category>> archivedOnce() {
    final q = (db.select(db.categories)
      ..where((t) => t.deletedAt.isNull() & t.isArchived.equals(true))
      ..orderBy([
        (t) => OrderingTerm.desc(t.updatedAt),
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

  Future<Category?> getById(int id) {
    final q = (db.select(db.categories)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull()));
    return q.getSingleOrNull();
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
        updatedAt: Value(DateTime.now()), // Using local time is OK for updatedAt
      ),
    );
  }

  Future<int> deleteSoft(int id) {
    return (db.update(db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        deletedAt: Value(DateTime.now()), // Using local time is OK for deletedAt
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> togglePin(int id, bool isPinned) {
    return (db.update(db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        isPinned: Value(isPinned),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> toggleArchive(int id, bool isArchived) {
    return (db.update(db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        isArchived: Value(isArchived),

        isPinned: isArchived ? const Value(false) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
