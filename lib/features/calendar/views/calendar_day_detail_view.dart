import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/db/app_database.dart';
import '../../../core/services/providers.dart';
import '../viewmodels/calendar_viewmodel.dart';
import '../../../core/routes/route_config.dart';
import '../../widgets/reminder_card.dart';

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
        return ReminderCard(
          reminder: reminder,
          categoryDao: ref.watch(categoryDaoProvider),
          onTap: () => context.push('/reminder/${reminder.id}'),
          showActions: false,
          showCategoryChip: true,
        );
      },
    );
  }

  void _addReminderOnDate(BuildContext context, DateTime date) {
    context.push('${AppRoutes.reminderNew}?date=${date.toIso8601String()}');
  }
}
