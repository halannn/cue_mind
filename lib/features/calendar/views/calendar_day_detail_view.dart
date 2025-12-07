import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/db/app_database.dart';
import '../../../core/services/providers.dart';
import '../viewmodels/calendar_viewmodel.dart';
import '../../../core/routes/route_config.dart';

/// Day detail view - shows all reminders for a specific day.
///
/// Spec implementation:
/// - Header with formatted date
/// - List of reminders with time, title, category chip
/// - Empty state with call-to-action
/// - Tap reminder to edit
/// - FAB for quick add with pre-filled date
class CalendarDayDetailView extends ConsumerWidget {
  final DateTime date;

  const CalendarDayDetailView({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalized = DateTime.utc(date.year, date.month, date.day);
    final remindersAsync = ref.watch(dayRemindersProvider(normalized));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(_formatDateHeader(normalized)),
        elevation: 0,
      ),
      body: remindersAsync.when(
        data: (reminders) => reminders.isEmpty
            ? _buildEmptyState(context, normalized)
            : _buildReminderList(context, ref, reminders),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading reminders: $error'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addReminderOnDate(context, normalized),
        tooltip: 'Add reminder',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Format date header: "Tue, 14 May 2025"
  String _formatDateHeader(DateTime date) {
    return DateFormat.yMMMMEEEEd().format(date);
  }

  /// Empty state widget
  Widget _buildEmptyState(BuildContext context, DateTime date) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No reminders scheduled for this day.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _addReminderOnDate(context, date),
              icon: const Icon(Icons.add),
              label: const Text('Add Reminder'),
            ),
          ],
        ),
      ),
    );
  }

  /// Reminder list widget
  Widget _buildReminderList(
    BuildContext context,
    WidgetRef ref,
    List<Reminder> reminders,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reminders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return _buildReminderCard(context, ref, reminder);
      },
    );
  }

  /// Individual reminder card
  Widget _buildReminderCard(
    BuildContext context,
    WidgetRef ref,
    Reminder reminder,
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
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _editReminder(context, reminder.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  DateFormat.Hm().format(scheduledTime),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Title and metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      reminder.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Description (if present)
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

                    // Metadata row (status, priority, category, recurrence)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Status chip
                        _buildStatusChip(theme, reminder.status),

                        // Priority chip
                        if (reminder.priority != null)
                          _buildPriorityChip(theme, reminder.priority!),

                        // Category chip
                        if (reminder.categoryId != null)
                          _buildCategoryChip(ref, reminder.categoryId!),

                        // Recurrence indicator
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

              // Chevron indicator
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Category color chip widget
  Widget _buildCategoryChip(WidgetRef ref, int categoryId) {
    // Create a stream provider for this category
    final categoryProvider = StreamProvider.autoDispose((streamRef) {
      final dao = streamRef.watch(categoryDaoProvider);
      return dao.watchById(categoryId);
    });

    final categoryAsync = ref.watch(categoryProvider);

    return categoryAsync.when(
      data: (category) {
        if (category == null) return const SizedBox.shrink();

        Color chipColor;
        try {
          final hex = category.colorHex.replaceFirst('#', '');
          chipColor = Color(int.parse('0xFF$hex'));
        } catch (_) {
          chipColor = Colors.grey;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: chipColor.withValues(alpha: 0.3), width: 1),
          ),
          child: Text(
            category.name,
            style: TextStyle(
              color: chipColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
      loading: () => const SizedBox(width: 16, height: 16),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  /// Status chip widget
  Widget _buildStatusChip(ThemeData theme, String status) {
    Color chipColor;
    String label;

    switch (status) {
      case 'done':
        chipColor = Colors.green;
        label = 'Selesai';
        break;
      case 'snoozed':
        chipColor = Colors.amber;
        label = 'Snooze';
        break;
      default: // pending
        chipColor = theme.colorScheme.primary;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: chipColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Priority chip widget
  Widget _buildPriorityChip(ThemeData theme, String priority) {
    Color chipColor;
    IconData icon;
    String label;

    switch (priority) {
      case 'high':
        chipColor = Colors.red;
        icon = Icons.arrow_upward;
        label = 'Tinggi';
        break;
      case 'low':
        chipColor = Colors.grey;
        icon = Icons.arrow_downward;
        label = 'Rendah';
        break;
      default: // normal
        chipColor = Colors.blue;
        icon = Icons.remove;
        label = 'Normal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: chipColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate to reminder editor with date pre-filled
  void _addReminderOnDate(BuildContext context, DateTime date) {
    context.push('${AppRoutes.reminderNew}?date=${date.toIso8601String()}');
  }

  /// Navigate to reminder detail view
  void _editReminder(BuildContext context, int reminderId) {
    context.push('/reminder/$reminderId');
  }
}
