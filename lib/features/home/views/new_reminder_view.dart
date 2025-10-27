import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/providers.dart';

class NewReminderView extends ConsumerStatefulWidget {
  const NewReminderView({super.key});
  @override
  ConsumerState<NewReminderView> createState() => _NewReminderViewState();
}

class _NewReminderViewState extends ConsumerState<NewReminderView> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  DateTime? whenLocal;
  int? categoryId;
  String? photoPath;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(reminderRepositoryProvider);
    final img = ref.read(imageServiceProvider);
    final catDao = ref.read(categoryDaoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Reminder')),
      body: FutureBuilder(
        future: catDao.allOnce(),
        builder: (ctx, snap) {
          final cats = snap.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Judul'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: categoryId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Kategori (opsional)'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('-')),
                  ...cats.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => setState(() => categoryId = v),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(
                    context: context,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 365)),
                    initialDate: now,
                  );
                  if (d == null) return;
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (t == null) return;
                  setState(() => whenLocal = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                },
                child: Text(
                  whenLocal == null
                      ? 'Pilih tanggal & waktu'
                      : DateFormat('EEE, d MMM yyyy • HH:mm').format(whenLocal!),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: Text(photoPath == null ? 'Lampirkan foto' : 'Ganti foto'),
                      onPressed: () async {
                        final p = await img.pickAndSave();
                        if (p != null) setState(() => photoPath = p);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (photoPath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(photoPath!), width: 64, height: 64, fit: BoxFit.cover),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty || whenLocal == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Judul & waktu wajib diisi')),
                    );
                    return;
                  }
                  final id = await repo.create(
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    categoryId: categoryId,
                    whenUtc: whenLocal!.toUtc(),
                    picturePath: photoPath,
                  );
                  if (!mounted) return;
                  context.pop(id > 0); // gunakan go_router pop
                },
                child: const Text('Simpan & Jadwalkan'),
              ),
            ],
          );
        },
      ),
    );
  }
}
