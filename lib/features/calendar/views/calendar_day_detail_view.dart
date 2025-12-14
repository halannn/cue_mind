import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/db/app_database.dart';
import '../../../core/services/providers.dart';
import '../viewmodels/calendar_viewmodel.dart';
import '../../../core/routes/route_config.dart';

class CalendarDayDetailView extends ConsumerWidget {
  final DateTime date;

  const CalendarDayDetailView({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalized = DateTime.utc(date.year, date.month, date.day);
    final remindersAsync = ref.watch(dayRemindersProvider(normalized));

    return Scaffold(
      appBar: remindersAsync.maybeWhen(
        data: (reminders) =>
            _buildAppBar(context, normalized, reminders.length),
        orElse: () => AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text(_formatDateHeader(normalized)),
          elevation: 0,
        ),
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

  String _formatDateHeader(DateTime date) {
    return DateFormat.yMMMMEEEEd().format(date);
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    DateTime date,
    int reminderCount,
  ) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_formatDateHeader(date)),
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
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No reminders scheduled for this day.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: InkWell(
        onTap: () => _editReminder(context, reminder.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

                        if (reminder.categoryId != null)
                          _buildCategoryChip(ref, reminder.categoryId!),

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

  Widget _buildCategoryChip(WidgetRef ref, int categoryId) {
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
            border: Border.all(
              color: chipColor.withValues(alpha: 0.3),
              width: 1,
            ),
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

  void _addReminderOnDate(BuildContext context, DateTime date) {
    context.push('${AppRoutes.reminderNew}?date=${date.toIso8601String()}');
  }

  void _editReminder(BuildContext context, int reminderId) {
    context.push('/reminder/$reminderId');
  }
}
