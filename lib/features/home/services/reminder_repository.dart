import 'package:drift/drift.dart';
import '../../../core/services/db/app_database.dart';
import '../../../core/services/db/daos/reminder_dao.dart';
import '../../../core/services/notification_service.dart';

class ReminderRepository {
  final AppDatabase db;
  final ReminderDao dao;
  final NotificationService notif;

  ReminderRepository({
    required this.db,
    required this.dao,
    required this.notif,
  });

  // Create + schedule notification
  Future<int> create({
    required String title,
    String? description,
    int? categoryId,
    required DateTime whenUtc,
    String? picturePath,
    String? thumbnailPath,
    String timezone = 'Asia/Makassar',
    String priority = 'normal',
  }) async {
    final id = await dao.insert(
      RemindersCompanion.insert(
        title: title,
        description: Value(description),
        categoryId: Value(categoryId),
        scheduledAt: whenUtc.millisecondsSinceEpoch,
        timezone: Value(timezone),
        picturePath: Value(picturePath),
        thumbnailPath: Value(thumbnailPath),
        priority: Value(priority),
      ),
    );

    // Jadwalkan notifikasi lokal (will skip if date is in the past)
    await notif.scheduleExact(
      id: id, // aman dipakai sebagai notificationId
      title: 'Cue Mind',
      body: title,
      fireTimeUtc: whenUtc,
    );

    return id;
  }

  Stream<List<Reminder>> watchUpcoming({int hours = 48}) =>
      dao.watchUpcomingHours(hours: hours);

  Future<void> markDone(int id) async {
    await dao.markDone(id);
    await notif.cancel(id);
  }

  Future<void> snooze(int id, Duration duration) async {
    final newWhen = DateTime.now().toUtc().add(duration);
    await dao.snoozeTo(id, newWhen.millisecondsSinceEpoch);
    await notif.cancel(id);
    await notif.scheduleExact(
      id: id,
      title: 'Cue Mind',
      body: 'Snoozed reminder',
      fireTimeUtc: newWhen,
    );
  }

  Future<void> delete(int id) async {
    await dao.softDelete(id);
    await notif.cancel(id);
  }

  Future<void> update({
    required int id,
    required String title,
    String? description,
    int? categoryId,
    required DateTime whenUtc,
    String? picturePath,
    String? recurrenceRule,
    String? timezone,
    String? priority,
    String? status,
  }) async {
    final hasRecurrence = recurrenceRule != null && recurrenceRule.isNotEmpty;

    await dao.updateById(
      id,
      RemindersCompanion(
        title: Value(title),
        description: Value(description),
        categoryId: Value(categoryId),
        scheduledAt: Value(whenUtc.millisecondsSinceEpoch),
        timezone: timezone != null ? Value(timezone) : const Value.absent(),
        picturePath: Value(picturePath),
        hasRecurrence: Value(hasRecurrence),
        recurrenceRule: Value(recurrenceRule),
        priority: priority != null ? Value(priority) : const Value.absent(),
        status: status != null ? Value(status) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    );

    // Reschedule notification (will skip if date is in the past)
    await notif.cancel(id);
    await notif.scheduleExact(
      id: id,
      title: 'Cue Mind',
      body: title,
      fireTimeUtc: whenUtc,
    );
  }
}
