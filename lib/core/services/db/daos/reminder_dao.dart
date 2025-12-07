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

  // === Analytics queries for monthly report ===

  /// Get status breakdown for a specific month.
  ///
  /// Returns map: {'done': count, 'pending': count, 'snoozed': count}
  Future<Map<String, int>> getMonthStatusBreakdown(DateTime monthUtc) async {
    final reminders = await getRemindersForMonth(monthUtc);

    final breakdown = <String, int>{
      'done': 0,
      'pending': 0,
      'snoozed': 0,
    };

    for (final reminder in reminders) {
      final status = reminder.status;
      if (breakdown.containsKey(status)) {
        breakdown[status] = breakdown[status]! + 1;
      }
    }

    return breakdown;
  }

  /// Get category distribution for a specific month.
  ///
  /// Returns list of tuples: [(categoryId, count), ...]
  Future<Map<int?, int>> getMonthCategoryDistribution(DateTime monthUtc) async {
    final reminders = await getRemindersForMonth(monthUtc);

    final distribution = <int?, int>{};

    for (final reminder in reminders) {
      final catId = reminder.categoryId;
      distribution[catId] = (distribution[catId] ?? 0) + 1;
    }

    return distribution;
  }

  /// Get weekday activity for a specific month.
  ///
  /// Returns map: {1: count (Monday), 2: count (Tuesday), ..., 7: count (Sunday)}
  ///
  /// CRITICAL: Converts scheduledAt from UTC to user timezone before grouping!
  Future<Map<int, int>> getMonthWeekdayActivity(
    DateTime monthUtc,
    String timezone,
  ) async {
    final reminders = await getRemindersForMonth(monthUtc);

    final activity = <int, int>{
      1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0,
    };

    for (final reminder in reminders) {
      // Convert UTC to local timezone
      final scheduledUtc = DateTime.fromMillisecondsSinceEpoch(
        reminder.scheduledAt,
        isUtc: true,
      );
      final scheduledLocal = scheduledUtc.toLocal();

      final weekday = scheduledLocal.weekday; // 1 = Monday, 7 = Sunday
      activity[weekday] = activity[weekday]! + 1;
    }

    return activity;
  }

  /// Get recurring vs one-time breakdown.
  ///
  /// Returns map: {'recurring': count, 'oneTime': count}
  Future<Map<String, int>> getMonthRecurringBreakdown(DateTime monthUtc) async {
    final reminders = await getRemindersForMonth(monthUtc);

    final breakdown = {
      'recurring': 0,
      'oneTime': 0,
    };

    for (final reminder in reminders) {
      if (reminder.hasRecurrence) {
        breakdown['recurring'] = breakdown['recurring']! + 1;
      } else {
        breakdown['oneTime'] = breakdown['oneTime']! + 1;
      }
    }

    return breakdown;
  }
}
