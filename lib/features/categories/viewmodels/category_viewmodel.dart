import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/db/app_database.dart';
import '../services/category_repository.dart';
import '../../../core/services/providers.dart';

enum ReminderStatusFilter {
  all('All'),
  pending('Pending'),
  done('Done'),
  snoozed('Snoozed');

  final String label;
  const ReminderStatusFilter(this.label);
}

enum ReminderPriorityFilter {
  all('All'),
  high('High'),
  normal('Normal'),
  low('Low');

  final String label;
  const ReminderPriorityFilter(this.label);
}

enum ReminderSortBy {
  dateAsc('Date (Oldest First)'),
  dateDesc('Date (Newest First)'),
  titleAsc('Title (A-Z)'),
  titleDesc('Title (Z-A)'),
  priorityHighFirst('Priority (High First)'),
  priorityLowFirst('Priority (Low First)');

  final String label;
  const ReminderSortBy(this.label);
}

class CategoryFilterState {
  final ReminderStatusFilter statusFilter;
  final ReminderPriorityFilter priorityFilter;
  final ReminderSortBy sortBy;
  final bool showRecurringOnly;

  const CategoryFilterState({
    this.statusFilter = ReminderStatusFilter.all,
    this.priorityFilter = ReminderPriorityFilter.all,
    this.sortBy = ReminderSortBy.dateAsc,
    this.showRecurringOnly = false,
  });

  CategoryFilterState copyWith({
    ReminderStatusFilter? statusFilter,
    ReminderPriorityFilter? priorityFilter,
    ReminderSortBy? sortBy,
    bool? showRecurringOnly,
  }) {
    return CategoryFilterState(
      statusFilter: statusFilter ?? this.statusFilter,
      priorityFilter: priorityFilter ?? this.priorityFilter,
      sortBy: sortBy ?? this.sortBy,
      showRecurringOnly: showRecurringOnly ?? this.showRecurringOnly,
    );
  }

  bool get hasActiveFilters =>
      statusFilter != ReminderStatusFilter.all ||
      priorityFilter != ReminderPriorityFilter.all ||
      showRecurringOnly;
}

class CategoryFilterNotifier extends Notifier<CategoryFilterState> {
  @override
  CategoryFilterState build() => const CategoryFilterState();

  void setStatusFilter(ReminderStatusFilter filter) {
    state = state.copyWith(statusFilter: filter);
  }

  void setPriorityFilter(ReminderPriorityFilter filter) {
    state = state.copyWith(priorityFilter: filter);
  }

  void setSortBy(ReminderSortBy sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void toggleRecurringOnly() {
    state = state.copyWith(showRecurringOnly: !state.showRecurringOnly);
  }

  void resetFilters() {
    state = const CategoryFilterState();
  }
}

final categoryFilterProvider =
    NotifierProvider.autoDispose<CategoryFilterNotifier, CategoryFilterState>(
      CategoryFilterNotifier.new,
    );

final filteredCategoryRemindersProvider =
    StreamProvider.family<List<Reminder>, int>((ref, categoryId) {
      final repo = ref.watch(categoryRepositoryProvider);

      return repo.watchRemindersByCategoryId(categoryId);
    });

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
