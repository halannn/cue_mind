import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/route_config.dart';
import '../../../core/services/providers.dart';
import '../../../core/services/db/app_database.dart';

class ReminderDetailView extends ConsumerWidget {
  final int id;
  const ReminderDetailView({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderDao = ref.watch(reminderDaoProvider);
    final categoryDao = ref.watch(categoryDaoProvider);

    return FutureBuilder<Reminder?>(
      future: reminderDao.getById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Reminder')),
            body: Center(child: Text('Reminder not found')),
          );
        }

        final reminder = snapshot.data!;
        final scheduled = DateTime.fromMillisecondsSinceEpoch(reminder.scheduledAt, isUtc: true).toLocal();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Reminder'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit',
                onPressed: () => AppRoutes.pushReminderEdit(context, id),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Delete reminder?'),
                      content: const Text('This action will remove the reminder. Are you sure?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Delete')),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await reminderDao.softDelete(id);
                    // Pop back after deletion
                    if (context.canPop()) context.pop();
                    // Optionally show a snackbar
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder deleted')));
                  }
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(reminder.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 8),
                    Text(DateFormat.yMMMMd().add_jm().format(scheduled)),
                    const Spacer(),
                    _statusChip(context, reminder.status),
                  ],
                ),
                const SizedBox(height: 12),
                if (reminder.categoryId != null)
                  StreamBuilder<Category?>(
                    stream: categoryDao.watchById(reminder.categoryId!),
                    builder: (context, snap) {
                      if (snap.hasData && snap.data != null) {
                        final cat = snap.data!;
                        Color color;
                        try {
                          final hex = cat.colorHex.replaceFirst('#', '');
                          color = Color(int.parse('0xFF$hex'));
                        } catch (_) {
                          color = Theme.of(context).colorScheme.primary;
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                          child: Text(cat.name, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                const SizedBox(height: 16),
                if (reminder.description != null && reminder.description!.isNotEmpty)
                  Text(reminder.description ?? '', style: Theme.of(context).textTheme.bodyLarge),
                const Spacer(),
                // Bottom actions
                
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(BuildContext context, String status) {
    Color c;
    switch (status) {
      case 'done':
        c = Colors.green;
        break;
      case 'snoozed':
        c = Colors.amber;
        break;
      default:
        c = Theme.of(context).colorScheme.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status[0].toUpperCase() + status.substring(1), style: TextStyle(color: c, fontWeight: FontWeight.w700)),
    );
  }
}
