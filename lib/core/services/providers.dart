import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/app_database.dart';
import 'db/daos/reminder_dao.dart';
import 'db/daos/category_dao.dart';

import 'notification_service.dart';
import 'image_service.dart';

import '../../features/home/services/reminder_repository.dart';
import '../../features/categories/services/category_repository.dart';

// =============================================================================
// DATABASE PROVIDERS
// =============================================================================
final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();

  ref.keepAlive;

  ref.onDispose(() {
    db.close();
  });

  return db;
});

// =============================================================================
// DAO PROVIDERS
// =============================================================================
final categoryDaoProvider = Provider<CategoryDao>(
  (ref) => CategoryDao(ref.watch(dbProvider)),
);
final reminderDaoProvider = Provider<ReminderDao>(
  (ref) => ReminderDao(ref.watch(dbProvider)),
);

// =============================================================================
// SERVICE PROVIDERS
// =============================================================================
final notificationServiceProvider = Provider<NotificationService>(
  (_) => NotificationService(),
);
final imageServiceProvider = Provider<ImageService>((_) => ImageService());

// =============================================================================
// REPOSITORY PROVIDERS
// =============================================================================
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

// =============================================================================
// BOOTSTRAP PROVIDER
// =============================================================================
final appBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(notificationServiceProvider).init();
});
