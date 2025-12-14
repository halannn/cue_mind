import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/category_viewmodel.dart';
import '../../../core/utils/color_hex.dart';
import '../../../core/routes/route_config.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/reminder_card.dart';
import '../../../core/services/providers.dart';

class CategoryView extends ConsumerWidget {
  final int id;
  const CategoryView({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(id));
    final reminders = ref.watch(categoryRemindersProvider(id));

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
        data: (items) => _buildAppBar(context, title, color, items.length),
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

          return _buildReminderList(context, ref, items, color);
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
    String categoryName,
    Color categoryColor,
    int reminderCount,
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
    List<dynamic> reminders,
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
}
