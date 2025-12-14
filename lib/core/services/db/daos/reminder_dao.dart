import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../../utils/datetime_utils.dart';

class ReminderDao {
  final AppDatabase db;
  ReminderDao(this.db);

  Future<int> insert(RemindersCompanion data) =>
      db.into(db.reminders).insert(data);

  Future<int> updateById(int id, RemindersCompanion data) =>
      (db.update(db.reminders)..where((t) => t.id.equals(id))).write(data);

  Future<int> softDelete(int id) =>
      (db.update(db.reminders)..where((t) => t.id.equals(id))).write(
        RemindersCompanion(
          deletedAt: Value(DateTimeUtils.nowUtc()),
          updatedAt: Value(DateTimeUtils.nowUtc()),
        ),
      );

  Future<int> markDone(int id) =>
      (db.update(db.reminders)..where((t) => t.id.equals(id))).write(
        const RemindersCompanion(status: Value('done')),
      );

  Future<int> snoozeTo(int id, int utcMillis) =>
      (db.update(db.reminders)..where((t) => t.id.equals(id))).write(
        RemindersCompanion(
          status: const Value('snoozed'),
          snoozedUntil: Value(utcMillis),
          scheduledAt: Value(utcMillis),
          updatedAt: Value(DateTimeUtils.nowUtc()),
        ),
      );

  Stream<List<Reminder>> watchUpcomingHours({int hours = 72}) {
    final now = DateTimeUtils.nowUtc().millisecondsSinceEpoch;
    final until = DateTimeUtils.hoursFromNowUtcMillis(hours);

    final q = db.select(db.reminders)
      ..where(
        (t) =>
            t.deletedAt.isNull() &
            t.scheduledAt.isBiggerOrEqualValue(now) &
            t.scheduledAt.isSmallerOrEqualValue(until) &
            t.status.isIn(['pending', 'snoozed']),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]);

    return q.watch();
  }

  Stream<List<Reminder>> watchByDayUtc(DateTime localDate) {
    final startUtc = DateTimeUtils.startOfDayUtc(localDate);
    final endUtc = DateTimeUtils.endOfDayUtc(localDate);

    final start = startUtc.millisecondsSinceEpoch;
    final end = endUtc.millisecondsSinceEpoch;

    final q = db.select(db.reminders)
      ..where(
        (t) => t.deletedAt.isNull() & t.scheduledAt.isBetweenValues(start, end),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]);

    return q.watch();
  }

  Future<Reminder?> getById(int id) => (db.select(
    db.reminders,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Reminder>> getRemindersForMonth(DateTime localMonth) async {
    final startUtc = DateTimeUtils.startOfMonthUtc(localMonth);
    final endUtc = DateTimeUtils.endOfMonthUtc(localMonth);

    final start = startUtc.millisecondsSinceEpoch;
    final end = endUtc.millisecondsSinceEpoch;

    final q = db.select(db.reminders)
      ..where(
        (t) => t.deletedAt.isNull() & t.scheduledAt.isBetweenValues(start, end),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]);

    final results = await q.get();

    return results;
  }

  Future<List<Reminder>> getRemindersForDay(DateTime localDay) async {
    final startUtc = DateTimeUtils.startOfDayUtc(localDay);
    final endUtc = DateTimeUtils.endOfDayUtc(localDay);

    final start = startUtc.millisecondsSinceEpoch;
    final end = endUtc.millisecondsSinceEpoch;

    final q = db.select(db.reminders)
      ..where(
        (t) => t.deletedAt.isNull() & t.scheduledAt.isBetweenValues(start, end),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]);

    return q.get();
  }

  Stream<List<Reminder>> watchRemindersForDay(DateTime localDay) {
    final startUtc = DateTimeUtils.startOfDayUtc(localDay);
    final endUtc = DateTimeUtils.endOfDayUtc(localDay);

    final start = startUtc.millisecondsSinceEpoch;
    final end = endUtc.millisecondsSinceEpoch;

    final q = db.select(db.reminders)
      ..where(
        (t) => t.deletedAt.isNull() & t.scheduledAt.isBetweenValues(start, end),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.scheduledAt)]);

    return q.watch();
  }

  Future<Map<String, int>> getMonthStatusBreakdown(DateTime localMonth) async {
    final reminders = await getRemindersForMonth(localMonth);

    final breakdown = <String, int>{'done': 0, 'pending': 0, 'snoozed': 0};

    for (final reminder in reminders) {
      final status = reminder.status;
      if (breakdown.containsKey(status)) {
        breakdown[status] = breakdown[status]! + 1;
      }
    }

    return breakdown;
  }

  Future<Map<int?, int>> getMonthCategoryDistribution(
    DateTime localMonth,
  ) async {
    final reminders = await getRemindersForMonth(localMonth);

    final distribution = <int?, int>{};

    for (final reminder in reminders) {
      final catId = reminder.categoryId;
      distribution[catId] = (distribution[catId] ?? 0) + 1;
    }

    return distribution;
  }

  Future<Map<int, int>> getMonthWeekdayActivity(DateTime localMonth) async {
    final reminders = await getRemindersForMonth(localMonth);

    final activity = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

    for (final reminder in reminders) {
      final scheduledLocal = DateTimeUtils.fromUtcMillis(reminder.scheduledAt);
      final weekday = scheduledLocal.weekday;
      activity[weekday] = activity[weekday]! + 1;
    }

    return activity;
  }

  Future<Map<String, int>> getMonthRecurringBreakdown(
    DateTime localMonth,
  ) async {
    final reminders = await getRemindersForMonth(localMonth);

    final breakdown = {'recurring': 0, 'oneTime': 0};

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
