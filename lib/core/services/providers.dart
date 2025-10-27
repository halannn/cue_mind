import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/app_database.dart';
import 'db/daos/reminder_dao.dart';
import 'db/daos/category_dao.dart';

import 'notification_service.dart';
import 'image_service.dart';

import '../../features/home/services/reminder_repository.dart';
import '../../features/categories/services/category_repository.dart';

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() {
    db.close();
  });
  return db;
});

final appBootstrapProvider = FutureProvider<void>((ref) async {
  await Future.wait([ref.read(notificationServiceProvider).init()]);

  ref.read(dbProvider);
  ref.read(categoryDaoProvider);
  ref.read(reminderDaoProvider);
});

final categoryDaoProvider = Provider<CategoryDao>(
  (ref) => CategoryDao(ref.watch(dbProvider)),
);
final reminderDaoProvider = Provider<ReminderDao>(
  (ref) => ReminderDao(ref.watch(dbProvider)),
);

final notificationServiceProvider = Provider<NotificationService>(
  (_) => NotificationService(),
);
final imageServiceProvider = Provider<ImageService>((_) => ImageService());

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository(
    db: ref.watch(dbProvider),
    dao: ref.watch(reminderDaoProvider),
    notif: ref.watch(notificationServiceProvider),
  );
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final dao = ref.watch(categoryDaoProvider);
  return CategoryRepository(dao);
});
