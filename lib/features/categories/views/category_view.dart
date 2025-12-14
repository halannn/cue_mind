import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/category_viewmodel.dart';
import '../../../core/utils/color_hex.dart';
import '../../../core/routes/route_config.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/reminder_card.dart';
import '../../../core/services/providers.dart';
import '../../../core/services/db/app_database.dart';

class CategoryView extends ConsumerWidget {
  final int id;
  const CategoryView({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(id));
    final reminders = ref.watch(categoryRemindersProvider(id));
    final filterState = ref.watch(categoryFilterProvider);

    final title = category.when(
      data: (c) => c?.name ?? 'Category',
      loading: () => 'Category',
      error: (_, _) => 'Category',
    );

    final color = category.when(
      data: (c) => (c?.colorHex ?? '#8E8E93').toColor(),
      loading: () => const Color(0xFF8E8E93),
      error: (_, _) => const Color(0xFF8E8E93),
    );

    return Scaffold(
      appBar: reminders.maybeWhen(
        data: (items) =>
            _buildAppBar(context, ref, title, color, items.length, filterState),
        orElse: () => AppBar(
          leading: IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.categories);
              }
            },
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(title),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CircleAvatar(radius: 10, backgroundColor: color),
            ),
          ],
        ),
      ),
      body: reminders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyState(context, color);
          }

          final filtered = _applyFiltersAndSort(items, filterState);

          if (filtered.isEmpty && filterState.hasActiveFilters) {
            return _buildNoResultsState(context, ref, color);
          }

          return _buildReminderList(context, ref, filtered, color);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AppRoutes.pushReminderNew(context),
        backgroundColor: color,
        tooltip: 'Add reminder',
        child: const Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    String categoryName,
    Color categoryColor,
    int reminderCount,
    CategoryFilterState filterState,
  ) {
    return AppBar(
      leading: IconButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.categories);
          }
        },
        icon: const Icon(Icons.arrow_back),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(categoryName),
            ],
          ),
          if (reminderCount > 0)
            Text(
              '$reminderCount reminder${reminderCount != 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      elevation: 0,
      actions: [
        if (filterState.hasActiveFilters)
          IconButton(
            icon: Badge(child: Icon(Icons.filter_alt)),
            onPressed: () => _showFilterSheet(context, ref, categoryColor),
            tooltip: 'Filter & Sort',
          )
        else
          IconButton(
            icon: Icon(Icons.filter_alt_outlined),
            onPressed: () => _showFilterSheet(context, ref, categoryColor),
            tooltip: 'Filter & Sort',
          ),
        IconButton(
          icon: Icon(Icons.sort),
          onPressed: () => _showSortSheet(context, ref, categoryColor),
          tooltip: 'Sort',
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, Color categoryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 64,
              color: categoryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No reminders yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a reminder to this category to get started',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderList(
    BuildContext context,
    WidgetRef ref,
    List<Reminder> reminders,
    Color categoryColor,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reminders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return ReminderCard(
          reminder: reminder,
          categoryDao: ref.watch(categoryDaoProvider),
          onTap: () => context.push('/reminder/${reminder.id}'),
          showActions: false,
          showCategoryChip: false,
          categoryColor: categoryColor,
        );
      },
    );
  }

  Widget _buildNoResultsState(
    BuildContext context,
    WidgetRef ref,
    Color categoryColor,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: categoryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No reminders found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () =>
                  ref.read(categoryFilterProvider.notifier).resetFilters(),
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  List<Reminder> _applyFiltersAndSort(
    List<Reminder> reminders,
    CategoryFilterState filterState,
  ) {
    var filtered = reminders;

    if (filterState.statusFilter != ReminderStatusFilter.all) {
      filtered = filtered
          .where((r) => r.status == filterState.statusFilter.name)
          .toList();
    }

    if (filterState.priorityFilter != ReminderPriorityFilter.all) {
      filtered = filtered
          .where((r) => r.priority == filterState.priorityFilter.name)
          .toList();
    }

    if (filterState.showRecurringOnly) {
      filtered = filtered.where((r) => r.hasRecurrence).toList();
    }

    switch (filterState.sortBy) {
      case ReminderSortBy.dateAsc:
        filtered.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        break;
      case ReminderSortBy.dateDesc:
        filtered.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        break;
      case ReminderSortBy.titleAsc:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case ReminderSortBy.titleDesc:
        filtered.sort((a, b) => b.title.compareTo(a.title));
        break;
      case ReminderSortBy.priorityHighFirst:
        filtered.sort((a, b) {
          final priorityOrder = {'high': 0, 'normal': 1, 'low': 2, null: 3};
          return (priorityOrder[a.priority] ?? 3).compareTo(
            priorityOrder[b.priority] ?? 3,
          );
        });
        break;
      case ReminderSortBy.priorityLowFirst:
        filtered.sort((a, b) {
          final priorityOrder = {'low': 0, 'normal': 1, 'high': 2, null: 3};
          return (priorityOrder[a.priority] ?? 3).compareTo(
            priorityOrder[b.priority] ?? 3,
          );
        });
        break;
    }

    return filtered;
  }

  void _showFilterSheet(
    BuildContext context,
    WidgetRef ref,
    Color categoryColor,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final filterState = ref.watch(categoryFilterProvider);
          final notifier = ref.read(categoryFilterProvider.notifier);

          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Reminders',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (filterState.hasActiveFilters)
                      TextButton(
                        onPressed: () => notifier.resetFilters(),
                        child: const Text('Clear All'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('Status', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ReminderStatusFilter.values.map((filter) {
                    final isSelected = filterState.statusFilter == filter;
                    return FilterChip(
                      label: Text(filter.label),
                      selected: isSelected,
                      onSelected: (_) => notifier.setStatusFilter(filter),
                      backgroundColor: isSelected
                          ? categoryColor.withValues(alpha: 0.2)
                          : null,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                Text('Priority', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ReminderPriorityFilter.values.map((filter) {
                    final isSelected = filterState.priorityFilter == filter;
                    return FilterChip(
                      label: Text(filter.label),
                      selected: isSelected,
                      onSelected: (_) => notifier.setPriorityFilter(filter),
                      backgroundColor: isSelected
                          ? categoryColor.withValues(alpha: 0.2)
                          : null,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                SwitchListTile(
                  title: const Text('Show recurring only'),
                  value: filterState.showRecurringOnly,
                  onChanged: (_) => notifier.toggleRecurringOnly(),
                  activeColor: categoryColor,
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSortSheet(
    BuildContext context,
    WidgetRef ref,
    Color categoryColor,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final filterState = ref.watch(categoryFilterProvider);
          final notifier = ref.read(categoryFilterProvider.notifier);

          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sort By', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                ...ReminderSortBy.values.map((sortOption) {
                  final isSelected = filterState.sortBy == sortOption;
                  return RadioListTile<ReminderSortBy>(
                    title: Text(sortOption.label),
                    value: sortOption,
                    groupValue: filterState.sortBy,
                    onChanged: (value) {
                      if (value != null) {
                        notifier.setSortBy(value);
                        Navigator.pop(context);
                      }
                    },
                    activeColor: categoryColor,
                    selected: isSelected,
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
