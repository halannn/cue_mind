import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/db/app_database.dart';
import '../services/category_repository.dart';
import '../../../core/services/providers.dart';

class CategoriesState {
  final AsyncValue<List<Category>> list;
  final String? error;
  const CategoriesState({this.list = const AsyncValue.loading(), this.error});

  CategoriesState copyWith({AsyncValue<List<Category>>? list, String? error}) =>
      CategoriesState(list: list ?? this.list, error: error);
}

class CategoriesVM extends Notifier<CategoriesState> {
  StreamSubscription<List<Category>>? _sub;

  CategoryRepository get _repo => ref.read(categoryRepositoryProvider);

  @override
  CategoriesState build() {
    state = const CategoriesState(list: AsyncValue.loading());

    _sub?.cancel();
    _sub = _repo.watchAll().listen(
      (data) => state = state.copyWith(list: AsyncValue.data(data)),
      onError: (e, st) => state = state.copyWith(list: AsyncValue.error(e, st)),
    );

    ref.onDispose(() => _sub?.cancel());

    return state;
  }

  Future<void> add(String name, String colorHex) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(error: 'Nama kategori wajib');
      return;
    }
    await _repo.create(name: name.trim(), colorHex: colorHex);
  }

  Future<void> edit(int id, String name, String colorHex) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(error: 'Nama kategori wajib');
      return;
    }
    await _repo.update(id: id, name: name.trim(), colorHex: colorHex);
  }

  Future<void> remove(int id) => _repo.deleteSoft(id);
}

final categoriesVMProvider = NotifierProvider<CategoriesVM, CategoriesState>(
  CategoriesVM.new,
);
