import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/home_viewmodel.dart';
import '../../../core/services/providers.dart';
import '../../widgets/reminder_card.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(homeVMProvider);
    final vm = ref.read(homeVMProvider.notifier);

    final body = s.upcoming.when(
      data: (value) => value.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: value.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => ReminderCard(
                reminder: value[i],
                categoryDao: ref.watch(categoryDaoProvider),
                onTap: () => context.push('/reminder/${value[i].id}'),
                onDone: () => vm.markDone(value[i].id),
                onSnooze: (duration) => vm.snooze(value[i].id, duration),
                onDelete: () => vm.delete(value[i].id),
                showActions: true,
                showCategoryChip: true,
              ),
            ),
      error: (e, _) => Center(child: Text('Error: $e')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upcoming Reminders'),
            s.upcoming.maybeWhen(
              data: (value) => value.isNotEmpty
                  ? Text(
                      '${value.length} reminder${value.length != 1 ? 's' : ''} in next 3 days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/reminder/new');
          if (result == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reminder created successfully')),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.photo_camera_back_outlined, size: 56),
            SizedBox(height: 12),
            Text(
              'No reminders for the next 3 days.\nTap + button to create.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
