import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/categories_viewmodel.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../../core/utils/color_hex.dart';
import 'package:go_router/go_router.dart';

class CategoriesView extends ConsumerWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(categoriesVMProvider);
    final vm = ref.read(categoriesVMProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: switch (s.list) {
        AsyncData(:final value) =>
          value.isEmpty
              ? const Center(child: Text('No categories yet.'))
              : ListView.separated(
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final c = value[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: HexColorParsing(c.colorHex).toColor(),
                      ),
                      title: Text(c.name),
                      trailing: PopupMenuButton<String>(
                        onSelected: (k) async {
                          if (k == 'edit') {
                            _showUpsertDialog(
                              context,
                              vm,
                              initialName: c.name,
                              initialColorHex: c.colorHex,
                              id: c.id,
                            );
                          } else if (k == 'delete') {
                            await vm.remove(c.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                      onTap: () =>
                      context.go('/categories/${c.id}')
                    );
                  },
                ),
        AsyncError(:final error) => Center(child: Text('Error: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUpsertDialog(context, vm),
        child: const Icon(Icons.add),
      ),
    );
  }
}

void _showUpsertDialog(
  BuildContext context,
  CategoriesVM vm, {
  int? id,
  String? initialName,
  String? initialColorHex,
}) {
  final nameCtrl = TextEditingController(text: initialName ?? '');
  Color pickedColor = HexColorParsing(initialColorHex ?? '#8E8E93').toColor();

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(id == null ? 'Add Category' : 'Delete Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Category Name'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Color:'),
                const SizedBox(width: 8),
                CircleAvatar(backgroundColor: pickedColor, radius: 12),
                const SizedBox(width: 8),
                Text(
                  pickedColor.toHex(includeAlpha: false),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 320,
              child: BlockPicker(
                pickerColor: pickedColor,
                onColorChanged: (c) => setState(() => pickedColor = c),
                availableColors: const [
                  Colors.red,
                  Colors.pink,
                  Colors.purple,
                  Colors.deepPurple,
                  Colors.indigo,
                  Colors.blue,
                  Colors.lightBlue,
                  Colors.cyan,
                  Colors.teal,
                  Colors.green,
                  Colors.lightGreen,
                  Colors.lime,
                  Colors.yellow,
                  Colors.amber,
                  Colors.orange,
                  Colors.deepOrange,
                  Colors.brown,
                  Colors.grey,
                  Colors.blueGrey,
                  Colors.black,
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final hex = pickedColor.toHex(includeAlpha: false);
              try {
                if (id == null) {
                  await vm.add(nameCtrl.text, hex);
                } else {
                  await vm.edit(id, nameCtrl.text, hex);
                }
                if (context.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: Text(id == null ? 'Save' : 'Update'),
          ),
        ],
      ),
    ),
  );
}
