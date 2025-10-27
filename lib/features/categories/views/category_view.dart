import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/category_viewmodel.dart';
import '../../../core/utils/color_hex.dart';

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
          if (items.isEmpty) {
            return const Center(child: Text('No reminders'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = items[i];
              return ListTile(
                leading: const Icon(Icons.alarm),
                title: Text(r.title),
                subtitle: Text(DateTime.fromMillisecondsSinceEpoch(r.scheduledAt).toLocal().toString()),
                onTap: () {
                  // Aksi saat tap reminder (opsional)
                },
              );
            },
          );
        },
      ),
    );
  }
}