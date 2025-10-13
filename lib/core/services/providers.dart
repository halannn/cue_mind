import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'db/app_database.dart';
import 'db/daos/category_dao.dart';
import '../../features/categories/services/category_repository.dart';

// DB
final dbProvider = Provider<AppDatabase>((_) => AppDatabase());

// DAOs
final categoryDaoProvider = Provider<CategoryDao>((ref) => CategoryDao(ref.watch(dbProvider)));

// Repository
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(categoryDaoProvider));
});
