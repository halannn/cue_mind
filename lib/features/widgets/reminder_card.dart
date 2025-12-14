import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/db/app_database.dart';

class ReminderCard extends ConsumerWidget {
  final Reminder reminder;
  final dynamic categoryDao;
  final VoidCallback onTap;
  final VoidCallback? onDone;
  final void Function(Duration)? onSnooze;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool showCategoryChip;
  final Color? categoryColor;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.categoryDao,
    required this.onTap,
    this.onDone,
    this.onSnooze,
    this.onDelete,
    this.showActions = true,
    this.showCategoryChip = true,
    this.categoryColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheduledTime = DateTime.fromMillisecondsSinceEpoch(
      reminder.scheduledAt,
      isUtc: true,
    ).toLocal();

    if (categoryColor != null) {
      return _buildCard(context, theme, scheduledTime, categoryColor, ref);
    }

    return StreamBuilder<Category?>(
      stream: reminder.categoryId != null
          ? categoryDao.watchById(reminder.categoryId!)
          : null,
      builder: (context, snapshot) {
        Color? fetchedColor;
        if (snapshot.hasData && snapshot.data != null) {
          try {
            final hex = snapshot.data!.colorHex.replaceFirst('#', '');
            fetchedColor = Color(int.parse('0xFF$hex'));
          } catch (_) {}
        }

        return _buildCard(context, theme, scheduledTime, fetchedColor, ref);
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    ThemeData theme,
    DateTime scheduledTime,
    Color? categoryColor,
    WidgetRef ref,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: categoryColor ?? theme.colorScheme.outlineVariant,
          width: categoryColor != null ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor != null
                      ? categoryColor.withValues(alpha: 0.15)
                      : theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                  border: categoryColor != null
                      ? Border.all(
                          color: categoryColor.withValues(alpha: 0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: Text(
                  DateFormat.Hm().format(scheduledTime),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color:
                        categoryColor ?? theme.colorScheme.onSecondaryContainer,
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

                    if (reminder.picturePath != null &&
                        reminder.picturePath!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(reminder.picturePath!),
                            height: 80,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 80,
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.broken_image,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusChip(theme, reminder.status),

                        if (reminder.priority != null)
                          _buildPriorityChip(theme, reminder.priority!),

                        if (showCategoryChip && reminder.categoryId != null)
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

              if (showActions)
                PopupMenuButton<String>(
                  onSelected: (k) => _handleMenuAction(context, k),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'done',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 8),
                          Text('Mark as done'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'snooze',
                      child: Row(
                        children: [
                          Icon(Icons.snooze, size: 20),
                          SizedBox(width: 8),
                          Text('Snooze'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                )
              else
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

  Future<void> _handleMenuAction(BuildContext context, String action) async {
    switch (action) {
      case 'done':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Mark as Done'),
            content: const Text('Mark this reminder as completed?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Mark Done'),
              ),
            ],
          ),
        );
        if (confirmed == true && onDone != null) onDone!();
        break;

      case 'snooze':
        final duration = await _showSnoozeDurationPicker(context);
        if (duration != null && context.mounted && onSnooze != null) {
          onSnooze!(duration);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Snoozed for ${_formatDuration(duration)}')),
          );
        }
        break;

      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Reminder'),
            content: const Text(
              'Are you sure you want to delete this reminder? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true && onDelete != null) onDelete!();
        break;
    }
  }

  Future<Duration?> _showSnoozeDurationPicker(BuildContext context) async {
    return showDialog<Duration>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Snooze Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.timelapse),
              title: const Text('10 minutes'),
              onTap: () =>
                  Navigator.pop(dialogContext, const Duration(minutes: 10)),
            ),
            ListTile(
              leading: const Icon(Icons.timelapse),
              title: const Text('30 minutes'),
              onTap: () =>
                  Navigator.pop(dialogContext, const Duration(minutes: 30)),
            ),
            ListTile(
              leading: const Icon(Icons.timelapse),
              title: const Text('1 hour'),
              onTap: () =>
                  Navigator.pop(dialogContext, const Duration(hours: 1)),
            ),
            ListTile(
              leading: const Icon(Icons.timelapse),
              title: const Text('2 hours'),
              onTap: () =>
                  Navigator.pop(dialogContext, const Duration(hours: 2)),
            ),
            ListTile(
              leading: const Icon(Icons.timelapse),
              title: const Text('Tomorrow (24 hours)'),
              onTap: () =>
                  Navigator.pop(dialogContext, const Duration(hours: 24)),
            ),
            const Divider(),
            ListTile(
              title: const Text('Custom...'),
              onTap: () async {
                final customDuration = await _showCustomDurationPicker(context);
                if (customDuration != null && dialogContext.mounted) {
                  Navigator.pop(dialogContext, customDuration);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<Duration?> _showCustomDurationPicker(BuildContext context) async {
    final controller = TextEditingController();

    return showDialog<Duration>(
      context: context,
      builder: (dialogContext) {
        String selectedUnit = 'minutes';

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Custom Snooze Duration'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration',
                      border: OutlineInputBorder(),
                      hintText: 'Enter a number',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Unit',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'minutes',
                        label: Text('Min', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: 'hours',
                        label: Text('Hour', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: 'days',
                        label: Text('Day', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    selected: {selectedUnit},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        selectedUnit = newSelection.first;
                      });
                    },
                    style: ButtonStyle(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final value = int.tryParse(controller.text);
                  if (value != null && value > 0) {
                    Duration duration;
                    switch (selectedUnit) {
                      case 'hours':
                        duration = Duration(hours: value);
                        break;
                      case 'days':
                        duration = Duration(days: value);
                        break;
                      default:
                        duration = Duration(minutes: value);
                    }
                    Navigator.pop(dialogContext, duration);
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }

  Widget _buildStatusChip(ThemeData theme, String status) {
    Color chipColor;
    Color textColor;
    String label;

    switch (status) {
      case 'done':
        chipColor = theme.brightness == Brightness.dark
            ? const Color(0xFF2E7D32)
            : const Color(0xFF4CAF50);
        textColor = Colors.white;
        label = 'Done';
        break;
      case 'snoozed':
        chipColor = theme.brightness == Brightness.dark
            ? const Color(0xFFF57C00)
            : const Color(0xFFFFA726);
        textColor = theme.brightness == Brightness.dark
            ? Colors.white
            : Colors.black87;
        label = 'Snoozed';
        break;
      default:
        chipColor = theme.colorScheme.primary;
        textColor = theme.colorScheme.onPrimary;
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
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(ThemeData theme, String priority) {
    Color chipColor;
    Color backgroundColor;
    IconData icon;
    String label;

    switch (priority) {
      case 'high':
        chipColor = theme.colorScheme.error;
        backgroundColor = theme.colorScheme.errorContainer;
        icon = Icons.arrow_upward;
        label = 'High';
        break;
      case 'low':
        chipColor = theme.colorScheme.outline;
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        icon = Icons.arrow_downward;
        label = 'Low';
        break;
      default:
        chipColor = theme.colorScheme.primary;
        backgroundColor = theme.colorScheme.primaryContainer;
        icon = Icons.remove;
        label = 'Normal';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withValues(alpha: 0.3), width: 1),
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(WidgetRef ref, int categoryId) {
    final categoryProvider = StreamProvider.autoDispose((streamRef) {
      return categoryDao.watchById(categoryId);
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
}
