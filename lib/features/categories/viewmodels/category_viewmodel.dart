import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/db/app_database.dart';
import '../services/category_repository.dart';
import '../../../core/services/providers.dart';

final categoryRemindersProvider =
    StreamProvider.family<List<Reminder>, int>((ref, id) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchRemindersByCategoryId(id);
});

final categoryByIdProvider = StreamProvider.family<Category?, int>((ref, id) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchById(id);
});

class CategoryState {
  final AsyncValue<List<Reminder>> list;
  final String? error;
  const CategoryState({this.list = const AsyncValue.loading(), this.error});

  CategoryState copyWith({AsyncValue<List<Reminder>>? list, String? error}) {
    return CategoryState(list: list ?? this.list, error: error ?? this.error);
  }
}

final categoryVMProvider = AsyncNotifierProvider.autoDispose.family<CategoryVM, CategoryState, int>(
  CategoryVM.new,
);

class CategoryVM extends AsyncNotifier<CategoryState> {
  StreamSubscription<List<Reminder>>? _sub;
  CategoryRepository get _repo => ref.read(categoryRepositoryProvider);

  CategoryVM(this.id);
  final int id;

  @override
  CategoryState build() {
    state = const AsyncValue.loading();

    _sub?.cancel();
    _sub = _repo
        .watchRemindersByCategoryId(id)
        .listen(
          (data) => state = AsyncValue.data(CategoryState(list: AsyncValue.data(data))),
          onError: (e, st) =>
              state = AsyncValue.data(CategoryState(list: AsyncValue.error(e, st))),
        );

    ref.onDispose(() => _sub?.cancel());

    return const CategoryState();
  }
}
