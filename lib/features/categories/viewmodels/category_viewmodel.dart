import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/db/app_database.dart';
import '../services/category_repository.dart';
import '../../../core/services/providers.dart';

final categoryRemindersProvider = StreamProvider.family<List<Reminder>, int>((
  ref,
  categoryId,
) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchRemindersByCategoryId(categoryId);
});

final categoryByIdProvider = StreamProvider.family<Category?, int>((
  ref,
  categoryId,
) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchById(categoryId);
});
