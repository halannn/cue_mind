import 'dart:io';

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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Reminder')),
            body: Center(child: Text('Reminder not found')),
          );
        }

        final reminder = snapshot.data!;
        final scheduled = DateTime.fromMillisecondsSinceEpoch(
          reminder.scheduledAt,
          isUtc: true,
        ).toLocal();

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
                      content: const Text(
                        'This action will remove the reminder. Are you sure?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(c).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(c).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await reminderDao.softDelete(id);

                    if (context.canPop()) context.pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reminder deleted')),
                    );
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  reminder.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DateFormat.yMMMMd().add_jm().format(scheduled),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(children: [_statusChip(context, reminder.status)]),
                const SizedBox(height: 12),

                if (reminder.priority != null)
                  _buildPriorityRow(context, reminder.priority!),

                const SizedBox(height: 16),

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
                        return Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cat.name,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                const SizedBox(height: 16),
                if (reminder.description != null &&
                    reminder.description!.isNotEmpty) ...[
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reminder.description ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                ],

                if (reminder.picturePath != null &&
                    reminder.picturePath!.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () =>
                        _showFullscreenImage(context, reminder.picturePath!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(reminder.picturePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                );
                              },
                            ),

                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (reminder.hasRecurrence ||
                    reminder.timezone != 'Asia/Makassar')
                  _buildInfoSection(context, reminder),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(BuildContext context, String status) {
    Color c;
    String label;
    switch (status) {
      case 'done':
        c = Colors.green;
        label = 'Done';
        break;
      case 'snoozed':
        c = Colors.amber;
        label = 'Snoozed';
        break;
      default:
        c = Theme.of(context).colorScheme.primary;
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildPriorityRow(BuildContext context, String priority) {
    IconData icon;
    String label;
    Color color;

    switch (priority) {
      case 'high':
        icon = Icons.arrow_upward;
        label = 'High Priority';
        color = Colors.red;
        break;
      case 'low':
        icon = Icons.arrow_downward;
        label = 'Low Priority';
        color = Colors.grey;
        break;
      default:
        icon = Icons.remove;
        label = 'Normal Priority';
        color = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, Reminder reminder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Information',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (reminder.hasRecurrence && reminder.recurrenceRule != null) ...[
            Row(
              children: [
                Icon(
                  Icons.repeat,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recurrence: ${_getRecurrenceText(reminder.recurrenceRule!)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (reminder.timezone != 'Asia/Makassar') const SizedBox(height: 8),
          ],
          if (reminder.timezone != 'Asia/Makassar') ...[
            Row(
              children: [
                Icon(
                  Icons.public,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Timezone: ${reminder.timezone}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getRecurrenceText(String rule) {
    if (rule.contains('FREQ=DAILY')) return 'Daily';
    if (rule.contains('FREQ=WEEKLY')) return 'Weekly';
    if (rule.contains('FREQ=MONTHLY')) return 'Monthly';
    return 'Custom';
  }

  void _showFullscreenImage(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
