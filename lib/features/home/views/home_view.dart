// lib/features/home/views/home_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/home_viewmodel.dart';
import '../../../core/services/db/app_database.dart';

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
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: value.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, i) => _ReminderTile(
                r: value[i],
                onDone: () => vm.markDone(value[i].id),
                onSnooze10m: () => vm.snooze(value[i].id, const Duration(minutes: 10)),
                onSnooze1h: () => vm.snooze(value[i].id, const Duration(hours: 1)),
                onDelete: () => vm.delete(value[i].id),
              ),
            ),
      error: (e, _) => Center(child: Text('Error: $e')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Cue Mind')),
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/reminder/new');
          if (result == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reminder dibuat')),
            );
          }
        },
        child: const Icon(Icons.add_a_photo),
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
              'Belum ada reminder untuk 48 jam ke depan.\nTap tombol + untuk membuat.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final Reminder r;
  final VoidCallback onDone;
  final VoidCallback onSnooze10m;
  final VoidCallback onSnooze1h;
  final VoidCallback onDelete;

  const _ReminderTile({
    required this.r,
    required this.onDone,
    required this.onSnooze10m,
    required this.onSnooze1h,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final when =
        DateTime.fromMillisecondsSinceEpoch(r.scheduledAt, isUtc: true).toLocal();
    final timeStr = DateFormat('EEE, d MMM yyyy • HH:mm').format(when);

    return ListTile(
      leading: r.picturePath == null
          ? const CircleAvatar(child: Icon(Icons.camera_alt))
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(r.picturePath!),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
      title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(timeStr),
      trailing: PopupMenuButton<String>(
        onSelected: (k) {
          switch (k) {
            case 'done':
              onDone();
              break;
            case 'snooze10':
              onSnooze10m();
              break;
            case 'snooze60':
              onSnooze1h();
              break;
            case 'delete':
              onDelete();
              break;
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'done', child: Text('Tandai selesai')),
          PopupMenuItem(value: 'snooze10', child: Text('Tunda 10 menit')),
          PopupMenuItem(value: 'snooze60', child: Text('Tunda 1 jam')),
          PopupMenuItem(value: 'delete', child: Text('Hapus')),
        ],
      ),
    );
  }
}
