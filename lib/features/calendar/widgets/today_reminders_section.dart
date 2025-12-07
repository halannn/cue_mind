import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/db/app_database.dart';
import '../../../core/services/providers.dart';

/// Today's Reminders Section Widget
///
/// Displays list of reminders for today at the bottom of calendar view.
/// Provides quick access to today's tasks without needing to tap on today's date.
class TodayRemindersSection extends ConsumerWidget {
  const TodayRemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);

    // Watch today's reminders
    final reminderDao = ref.watch(reminderDaoProvider);

    return StreamBuilder<List<Reminder>>(
      stream: reminderDao.watchRemindersForDay(todayUtc),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading reminders',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          );
        }

        final reminders = snapshot.data ?? [];

        if (reminders.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'No reminders for today',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enjoy your free time! 🌿',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Icon(
                    Icons.today,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Reminders",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${reminders.length}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Reminder list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: reminders.length,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  return _TodayReminderItem(reminder: reminder);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Individual reminder item for today's list
class _TodayReminderItem extends ConsumerWidget {
  final Reminder reminder;

  const _TodayReminderItem({required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledDate = DateTime.fromMillisecondsSinceEpoch(
      reminder.scheduledAt,
      isUtc: true,
    ).toLocal();

    // Get category info if exists
    if (reminder.categoryId != null) {
      final categoryDao = ref.watch(categoryDaoProvider);

      return StreamBuilder<Category?>(
        stream: categoryDao.watchById(reminder.categoryId!),
        builder: (context, snapshot) {
          String? categoryName;
          Color? categoryColor;

          if (snapshot.hasData && snapshot.data != null) {
            final category = snapshot.data!;
            categoryName = category.name;
            try {
              final hex = category.colorHex.replaceFirst('#', '');
              categoryColor = Color(int.parse('0xFF$hex'));
            } catch (_) {
              categoryColor = Theme.of(context).colorScheme.primary;
            }
          }

          return _buildReminderContent(context, scheduledDate, categoryName, categoryColor);
        },
      );
    }

    return _buildReminderContent(context, scheduledDate, null, null);
  }

  Widget _buildReminderContent(
    BuildContext context,
    DateTime scheduledDate,
    String? categoryName,
    Color? categoryColor,
  ) {
    return InkWell(
      onTap: () {
        // Navigate to reminder detail (view) first
        context.push('/reminder/${reminder.id}');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: _getStatusColor(context, reminder.status),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    reminder.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      decoration: reminder.status == 'done'
                          ? TextDecoration.lineThrough
                          : null,
                      color: reminder.status == 'done'
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Time and category
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat.jm().format(scheduledDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (categoryName != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: categoryColor?.withValues(alpha: 0.15) ??
                                   Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: categoryColor?.withValues(alpha: 0.3) ??
                                     Theme.of(context).colorScheme.primary,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: categoryColor ?? Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Status and Priority badges
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(context, reminder.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(reminder.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(context, reminder.status),
                    ),
                  ),
                ),

                // Priority badge
                if (reminder.priority != null && reminder.priority != 'normal') ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(reminder.priority!).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPriorityIcon(reminder.priority!),
                          size: 10,
                          color: _getPriorityColor(reminder.priority!),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _getPriorityLabel(reminder.priority!),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getPriorityColor(reminder.priority!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'done':
        return Colors.green;
      case 'snoozed':
        return Colors.amber;
      case 'pending':
      default:
        return Colors.blue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'done':
        return 'Done';
      case 'snoozed':
        return 'Snoozed';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.grey;
      case 'normal':
      default:
        return Colors.blue;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return Icons.arrow_upward;
      case 'low':
        return Icons.arrow_downward;
      case 'normal':
      default:
        return Icons.remove;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'High';
      case 'low':
        return 'Low';
      case 'normal':
      default:
        return 'Normal';
    }
  }
}
