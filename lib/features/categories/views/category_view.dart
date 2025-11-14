import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      error: (_, _) => 'Category',
    );

    final color = category.when(
      data: (c) => (c?.colorHex ?? '#8E8E93').toColor(),
      loading: () => const Color(0xFF8E8E93),
      error: (_, _) => const Color(0xFF8E8E93),
    );

    return Scaffold(
      appBar: AppBar(
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
      body: reminders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          // Empty state with CTA (per spec)
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_note_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No reminders yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a reminder to this category to get started',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => AppRoutes.pushReminderNew(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Reminder'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Reminder list
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = items[i];
              return ListTile(
                leading: const Icon(Icons.alarm),
                title: Text(r.title),
                subtitle: Text(
                  DateTime.fromMillisecondsSinceEpoch(
                    r.scheduledAt,
                  ).toLocal().toString(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
