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
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ArchivedCategoriesView()),
            ),
            tooltip: 'View Archived',
          ),
        ],
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
                      title: Row(
                        children: [
                          Expanded(child: Text(c.name)),
                          if (c.isPinned)
                            Icon(
                              Icons.push_pin,
                              size: 16,
                              color: HexColorParsing(c.colorHex).toColor(),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              c.isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              color: c.isPinned
                                  ? HexColorParsing(c.colorHex).toColor()
                                  : null,
                            ),
                            onPressed: () => vm.togglePin(c.id, c.isPinned),
                            tooltip: c.isPinned ? 'Unpin' : 'Pin',
                          ),
                          PopupMenuButton<String>(
                            onSelected: (k) async {
                              if (k == 'edit') {
                                _showUpsertDialog(
                                  context,
                                  vm,
                                  initialName: c.name,
                                  initialColorHex: c.colorHex,
                                  id: c.id,
                                );
                              } else if (k == 'archive') {
                                await vm.toggleArchive(c.id, c.isArchived);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Category archived'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } else if (k == 'delete') {
                                await _showDeleteConfirmation(context, vm, c);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'archive',
                                child: Row(
                                  children: [
                                    Icon(Icons.archive_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text('Archive'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

class ArchivedCategoriesView extends ConsumerWidget {
  const ArchivedCategoriesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(archivedCategoriesVMProvider);
    final vm = ref.read(archivedCategoriesVMProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Archived Categories',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: switch (s.list) {
        AsyncData(:final value) =>
          value.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.archive_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No archived categories',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
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
                      subtitle: Text(
                        'Archived',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (k) async {
                          if (k == 'unarchive') {
                            await vm.unarchive(c.id);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${c.name} restored'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } else if (k == 'delete') {
                            await _showArchivedDeleteConfirmation(
                              context,
                              vm,
                              c,
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'unarchive',
                            child: Row(
                              children: [
                                Icon(Icons.unarchive_outlined, size: 20),
                                SizedBox(width: 8),
                                Text('Restore'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_forever_outlined,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete Permanently',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        AsyncError(:final error) => Center(child: Text('Error: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

Future<void> _showArchivedDeleteConfirmation(
  BuildContext context,
  ArchivedCategoriesVM vm,
  Category category,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Permanently?'),
      content: Text(
        'Are you sure you want to permanently delete "${category.name}"? '
        'This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await vm.deletePermanently(category.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${category.name} deleted permanently')),
      );
    }
  }
}
