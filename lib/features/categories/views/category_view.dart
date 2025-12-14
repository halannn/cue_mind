import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../viewmodels/category_viewmodel.dart';
import '../../../core/utils/color_hex.dart';
import '../../../core/routes/route_config.dart';
import 'package:go_router/go_router.dart';

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
      error: (_, __) => 'Category',
    );

    final color = category.when(
      data: (c) => (c?.colorHex ?? '#8E8E93').toColor(),
      loading: () => const Color(0xFF8E8E93),
      error: (_, __) => const Color(0xFF8E8E93),
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

          return _buildReminderList(context, items, color);
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
    List<dynamic> reminders,
    Color categoryColor,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reminders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return _buildReminderCard(context, reminder, categoryColor);
      },
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    dynamic reminder,
    Color categoryColor,
  ) {
    final theme = Theme.of(context);
    final scheduledTime = DateTime.fromMillisecondsSinceEpoch(
      reminder.scheduledAt,
      isUtc: true,
    ).toLocal();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: InkWell(
        onTap: () => context.push('/reminder/${reminder.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  DateFormat.Hm().format(scheduledTime),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: categoryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      DateFormat.yMMMMd().format(scheduledTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (reminder.description != null &&
                        reminder.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          reminder.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusChip(theme, reminder.status),

                        if (reminder.priority != null)
                          _buildPriorityChip(theme, reminder.priority!),

                        if (reminder.hasRecurrence)
                          Icon(
                            Icons.repeat,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme, String status) {
    Color chipColor;
    String label;

    switch (status) {
      case 'done':
        chipColor = Colors.green;
        label = 'Done';
        break;
      case 'snoozed':
        chipColor = Colors.amber;
        label = 'Snoozed';
        break;
      default:
        chipColor = theme.colorScheme.primary;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(ThemeData theme, String priority) {
    Color chipColor;
    IconData icon;
    String label;

    switch (priority) {
      case 'high':
        chipColor = Colors.red;
        icon = Icons.arrow_upward;
        label = 'High';
        break;
      case 'low':
        chipColor = Colors.grey;
        icon = Icons.arrow_downward;
        label = 'Low';
        break;
      default:
        chipColor = theme.colorScheme.onSurfaceVariant;
        icon = Icons.remove;
        label = 'Normal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: chipColor),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
