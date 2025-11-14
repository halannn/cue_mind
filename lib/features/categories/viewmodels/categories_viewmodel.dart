import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<String?> _validateCategoryName(String name, {int? excludeId}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'Please enter a category name.';
    }

    if (trimmed.length > 30) {
      return 'Category name must be 30 characters or less.';
    }

    final isDuplicate = await _repo.nameExists(trimmed, excludeId: excludeId);
    if (isDuplicate) {
      return 'This category name already exists.';
    }

    return null;
  }

  Future<String?> add(String name, String colorHex) async {
    final error = await _validateCategoryName(name);
    if (error != null) {
      state = state.copyWith(error: error);
      return error;
    }
    await _repo.create(name: name.trim(), colorHex: colorHex);
    state = state.copyWith(error: error);
    return null;
  }

  Future<String?> edit(int id, String name, String colorHex) async {
    final error = await _validateCategoryName(name, excludeId: id);
    if (error != null) {
      state = state.copyWith(error: error);
      return error;
    }
    await _repo.update(id: id, name: name.trim(), colorHex: colorHex);
    state = state.copyWith(error: error);
    return null;
  }

  Future<void> remove(int id) => _repo.deleteSoft(id);
}

final categoriesVMProvider = NotifierProvider<CategoriesVM, CategoriesState>(
  CategoriesVM.new,
);
