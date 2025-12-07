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
          // updatedAt: Value(DateTime.now()),
        ),
      );

  Future<int> snoozeTo(int id, int utcMillis) =>
      (db.update(db.reminders)..where((t) => t.id.equals(id))).write(
        RemindersCompanion(
          status: const Value('snoozed'),
          snoozedUntil: Value(utcMillis),
          scheduledAt: Value(utcMillis),
          updatedAt: Value(DateTime.now()),
        ),
      );

  // === Queries untuk Home ===

  /// Stream upcoming reminders (status pending/snoozed)
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

  /// Stream semua reminder untuk hari tertentu.
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

  // Query single
  Future<Reminder?> getById(int id) =>
      (db.select(db.reminders)..where((t) => t.id.equals(id))).getSingleOrNull();

  // === Calendar-specific queries ===

  /// Get all reminders for a specific month (UTC).
  ///
  /// Used by calendar to calculate density and category highlights.
  Future<List<Reminder>> getRemindersForMonth(DateTime monthUtc) async {
    final start = DateTime.utc(monthUtc.year, monthUtc.month, 1)
        .millisecondsSinceEpoch;
    final end = DateTime.utc(monthUtc.year, monthUtc.month + 1, 1)
        .subtract(const Duration(seconds: 1))
        .millisecondsSinceEpoch;

    final q = db.select(db.reminders)
      ..where((t) =>
          t.deletedAt.isNull() &
          t.scheduledAt.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]);

    return q.get();
  }

  /// Get all reminders for a specific day (UTC).
  ///
  /// Used by day detail view.
  Future<List<Reminder>> getRemindersForDay(DateTime dayUtc) async {
    final start = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day)
        .millisecondsSinceEpoch;
    final end = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day, 23, 59, 59)
        .millisecondsSinceEpoch;

    final q = db.select(db.reminders)
      ..where((t) =>
          t.deletedAt.isNull() &
          t.scheduledAt.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]);

    return q.get();
  }

  /// Stream reminders for a specific day (for reactive day detail view).
  Stream<List<Reminder>> watchRemindersForDay(DateTime dayUtc) {
    final start = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day)
        .millisecondsSinceEpoch;
    final end = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day, 23, 59, 59)
        .millisecondsSinceEpoch;

    final q = db.select(db.reminders)
      ..where((t) =>
          t.deletedAt.isNull() &
          t.scheduledAt.isBetweenValues(start, end))
      ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]);

    return q.watch();
  }

  Future<void> update({
    required int id,
    required String title,
    String? description,
    int? categoryId,
    required DateTime whenUtc,
    String? picturePath,
    String? recurrenceRule,
  }) async {
    final hasRecurrence = recurrenceRule != null && recurrenceRule.isNotEmpty;

    await updateById(
      id,
      RemindersCompanion(
        title: Value(title),
        description: Value(description),
        categoryId: Value(categoryId),
        scheduledAt: Value(whenUtc.millisecondsSinceEpoch),
        picturePath: Value(picturePath),
        hasRecurrence: Value(hasRecurrence),
        recurrenceRule: Value(recurrenceRule),
        updatedAt: Value(DateTime.now()),
      ),
    );

    // TODO: Reschedule notification - notif service needs to be injected
    // await notif.cancel(id);
    // await notif.scheduleExact(
    //   id: id,
    //   title: 'Cue Mind',
    //   body: title,
    //   fireTimeUtc: whenUtc,
    // );
  }
}
