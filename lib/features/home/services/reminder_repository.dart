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
  }) async {
    final id = await dao.insert(
      RemindersCompanion.insert(
        title: title,
        description: Value(description),
        categoryId: Value(categoryId),
        scheduledAt: whenUtc.millisecondsSinceEpoch,
        timezone: Value(timezone), // ✅ FIX di sini
        picturePath: Value(picturePath),
        thumbnailPath: Value(thumbnailPath),
      ),
    );

    // Jadwalkan notifikasi lokal
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
}
