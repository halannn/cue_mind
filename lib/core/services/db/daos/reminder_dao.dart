import 'package:drift/drift.dart';
import '../app_database.dart';

class ReminderDao {
  final AppDatabase db;
  ReminderDao(this.db);

  // Insert / Update / Delete (soft)
  Future<int> insert(RemindersCompanion data) =>
      db.into(db.reminders).insert(data);

  Future<int> updateById(int id, RemindersCompanion data) =>
      (db.update(db.reminders)..where((t) => t.id.equals(id))).write(data);

  Future<int> softDelete(int id) =>
      (db.update(db.reminders)..where((t) => t.id.equals(id))).write(
        RemindersCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

  // Mark done & snooze
  Future<int> markDone(int id) =>
      (db.update(db.reminders)..where((t) => t.id.equals(id))).write(
        const RemindersCompanion(
          status: Value('done'),
          // optional tapi baik untuk audit:
          // updatedAt: Value(DateTime.now()),
        ),
      );

  Future<int> snoozeTo(int id, int utcMillis) =>
      (db.update(db.reminders)..where((t) => t.id.equals(id))).write(
        RemindersCompanion(
          status: const Value('snoozed'),
          snoozedUntil: Value(utcMillis),
          scheduledAt: Value(utcMillis),        // <-- FIX: bungkus Value()
          updatedAt: Value(DateTime.now()),
        ),
      );

  // === Queries untuk Home ===

  /// Stream upcoming reminders (status pending/snoozed) dalam jendela jam ke depan.
  Stream<List<Reminder>> watchUpcomingHours({int hours = 48}) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final until =
        DateTime.now().toUtc().add(Duration(hours: hours)).millisecondsSinceEpoch;

    final q = db.select(db.reminders)
      ..where((t) =>
          t.deletedAt.isNull() &
          t.scheduledAt.isBiggerOrEqualValue(now) &
          t.scheduledAt.isSmallerOrEqualValue(until) &
          t.status.isIn(['pending', 'snoozed']))
      ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]);

    return q.watch();
  }

  /// Stream semua reminder untuk hari tertentu (UTC hari itu).
  Stream<List<Reminder>> watchByDayUtc(DateTime dayUtc) {
    final start =
        DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day).millisecondsSinceEpoch;
    final end = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day, 23, 59, 59)
        .millisecondsSinceEpoch;

    final q = db.select(db.reminders)
      ..where((t) =>
          t.deletedAt.isNull() & t.scheduledAt.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]);

    return q.watch();
  }

  // Query single (untuk edit)
  Future<Reminder?> getById(int id) =>
      (db.select(db.reminders)..where((t) => t.id.equals(id))).getSingleOrNull();
}
