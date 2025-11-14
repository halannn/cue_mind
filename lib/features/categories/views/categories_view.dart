import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/categories_viewmodel.dart';
import '../../../core/utils/color_hex.dart';
import '../../../core/routes/route_config.dart';
import '../widgets/category_color_picker.dart';
import '../services/category_repository.dart';

class CategoriesView extends ConsumerWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(categoriesVMProvider);
    final vm = ref.read(categoriesVMProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
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
                        maxRadius: 16,
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
                            await _showDeleteConfirmation(context, vm, c);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                      onTap: () => AppRoutes.pushCategoryDetail(context, c.id),
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
        title: Text(id == null ? 'Add Category' : 'Edit Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  helperText: 'Max 30 characters',
                ),
                maxLength: 30,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              CategoryColorPicker(
                selectedColor: pickedColor,
                onColorChanged: (c) => setState(() => pickedColor = c),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final hex = pickedColor.toHex(includeAlpha: false);

              final error = id == null
                  ? await vm.add(nameCtrl.text, hex)
                  : await vm.edit(id, nameCtrl.text, hex);

              if (error == null && ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      id == null ? 'Category added' : 'Category updated',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else if (error != null && ctx.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error)));
              }
            },
            child: Text(id == null ? 'Save' : 'Update'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showDeleteConfirmation(
  BuildContext context,
  CategoriesVM vm,
  Category category,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Delete "${category.name}"?'),
      content: const Text('This will not delete its reminders.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await vm.remove(category.id);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${category.name} deleted')));
    }
  }
}
