import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/db/app_database.dart';
import '../../../core/services/providers.dart';
import '../../../core/services/image_service.dart';
import '../../../core/utils/color_hex.dart';
import '../../../core/routes/route_config.dart';

class ReminderEditorView extends ConsumerStatefulWidget {
  final int? reminderId;
  final DateTime? initialDate;

  const ReminderEditorView({super.key, this.reminderId, this.initialDate});

  @override
  ConsumerState<ReminderEditorView> createState() => _ReminderEditorViewState();
}

class _ReminderEditorViewState extends ConsumerState<ReminderEditorView> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? _scheduledDateTime;
  int? _categoryId;
  String? _photoPath;
  String _priority = 'normal';
  String _status = 'pending';

  RecurrenceType _recurrenceType = RecurrenceType.none;
  String? _recurrenceRule;

  bool _isLoading = false;
  bool _isInitialized = false;

  bool get _isEditMode => widget.reminderId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadExistingReminder();
    } else {
      _scheduledDateTime =
          widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
      _isInitialized = true;
    }
  }

  Future<void> _loadExistingReminder() async {
    try {
      final dao = ref.read(reminderDaoProvider);
      final reminder = await dao.getById(widget.reminderId!);

      if (reminder == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Reminder not found')));
          context.pop();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _titleController.text = reminder.title;
          _descriptionController.text = reminder.description ?? '';
          _scheduledDateTime = DateTime.fromMillisecondsSinceEpoch(
            reminder.scheduledAt,
          ).toLocal();
          _categoryId = reminder.categoryId;
          _photoPath = reminder.picturePath;
          _priority = reminder.priority ?? 'normal';
          _status = reminder.status;
          _recurrenceType = reminder.hasRecurrence
              ? _parseRecurrenceType(reminder.recurrenceRule)
              : RecurrenceType.none;
          _recurrenceRule = reminder.recurrenceRule;
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading reminder: $e')));
        context.pop();
      }
    }
  }

  RecurrenceType _parseRecurrenceType(String? rule) {
    if (rule == null) return RecurrenceType.none;
    if (rule.contains('FREQ=DAILY')) return RecurrenceType.daily;
    if (rule.contains('FREQ=WEEKLY')) return RecurrenceType.weekly;
    if (rule.contains('FREQ=MONTHLY')) return RecurrenceType.monthly;
    return RecurrenceType.custom;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text(_isEditMode ? 'Edit Reminder' : 'New Reminder'),
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTitleField(),
                      const SizedBox(height: 16),
                      _buildDescriptionField(),
                      const SizedBox(height: 24),
                      _buildCategorySelector(),
                      const SizedBox(height: 24),
                      _buildPhotoSection(),
                      const SizedBox(height: 24),
                      _buildDateTimePicker(),
                      const SizedBox(height: 24),
                      _buildPrioritySelector(),
                      const SizedBox(height: 24),
                      if (_isEditMode) ...[
                        _buildStatusSelector(),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + MediaQuery.of(context).padding.bottom,
              ),
              child: _isEditMode
                  ? _buildEditModeButtons()
                  : _buildCreateButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Title',
        border: OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Title is required';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description (optional)',
        border: OutlineInputBorder(),
      ),
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category (optional)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showCategoryBottomSheet,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildCategoryChip(),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip() {
    return FutureBuilder<Category?>(
      future: _categoryId == null
          ? Future.value(null)
          : ref.read(categoryDaoProvider).watchById(_categoryId!).first,
      builder: (context, snapshot) {
        final category = snapshot.data;

        if (category == null) {
          return Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: const Color(0xFF8E8E93),
              ),
              const SizedBox(width: 8),
              const Text('-'),
            ],
          );
        }

        return Row(
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: category.colorHex.toColor(),
            ),
            const SizedBox(width: 8),
            Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCategoryBottomSheet() async {
    final categories = await ref.read(categoryDaoProvider).allOnce();

    if (!mounted) return;

    final selected = await showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Select Category',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFF8E8E93),
                      ),
                      title: const Text('-'),
                      trailing: _categoryId == null
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
                      onTap: () => Navigator.pop(context, -1),
                    ),
                    const Divider(height: 1),

                    ...categories.map((cat) {
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: cat.colorHex.toColor(),
                        ),
                        title: Text(cat.name),
                        trailing: _categoryId == cat.id
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                        onTap: () => Navigator.pop(context, cat.id),
                      );
                    }),
                  ],
                ),
              ),

              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    AppRoutes.goCategories(context);
                  },
                  child: const Text('Manage Categories'),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (selected != null) {
      setState(() {
        _categoryId = selected == -1 ? null : selected;
      });
    }
  }

  Widget _buildDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: _showDateTimeBottomSheet,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            _scheduledDateTime == null
                ? 'Select date & time'
                : DateFormat(
                    'EEE, d MMM yyyy • HH:mm',
                  ).format(_scheduledDateTime!),
            style: const TextStyle(fontSize: 16),
          ),
        ),

        if (_recurrenceType != RecurrenceType.none) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.repeat, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  _recurrenceType.displayName,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showRecurrenceOption,
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showDateTimeBottomSheet() async {
    final now = DateTime.now();

    final firstDate =
        _isEditMode &&
            _scheduledDateTime != null &&
            _scheduledDateTime!.isBefore(now)
        ? DateTime(2020, 1, 1)
        : now;

    DateTime initialDate;
    if (_scheduledDateTime != null) {
      if (_scheduledDateTime!.isBefore(firstDate)) {
        initialDate = firstDate;
      } else {
        initialDate = _scheduledDateTime!;
      }
    } else {
      initialDate = now;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledDateTime != null
          ? TimeOfDay.fromDateTime(_scheduledDateTime!)
          : TimeOfDay.now(),
    );

    if (time == null || !mounted) return;

    setState(() {
      _scheduledDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });

    if (mounted) {
      _showRecurrenceOption();
    }
  }

  Future<void> _showRecurrenceOption() async {
    final selected = await showModalBottomSheet<RecurrenceType>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Recurrence',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),

          ...RecurrenceType.values.map((type) {
            return ListTile(
              title: Text(type.displayName),
              trailing: _recurrenceType == type
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () => Navigator.pop(context, type),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (selected != null && selected != _recurrenceType) {
      setState(() {
        _recurrenceType = selected;
        _recurrenceRule = _buildRecurrenceRule(selected);
      });
    }
  }

  String? _buildRecurrenceRule(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none:
        return null;
      case RecurrenceType.daily:
        return 'FREQ=DAILY;INTERVAL=1';
      case RecurrenceType.weekly:
        return 'FREQ=WEEKLY;INTERVAL=1';
      case RecurrenceType.monthly:
        return 'FREQ=MONTHLY;INTERVAL=1';
      case RecurrenceType.custom:
        return 'FREQ=WEEKLY;INTERVAL=2';
    }
  }

  Widget _buildPhotoSection() {
    if (_photoPath == null) {
      return OutlinedButton.icon(
        onPressed: _pickPhoto,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Attach photo'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _showFullScreenImage,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.file(File(_photoPath!), fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _photoPath = null),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Change photo'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSourceType>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                subtitle: const Text('Use camera to capture new photo'),
                onTap: () => Navigator.pop(context, ImageSourceType.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                subtitle: const Text('Select existing photo from device'),
                onTap: () => Navigator.pop(context, ImageSourceType.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final img = ref.read(imageServiceProvider);
    final path = await img.pickFromSource(source);
    if (path != null && mounted) {
      setState(() => _photoPath = path);
    }
  }

  void _showFullScreenImage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenImageViewer(imagePath: _photoPath!),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Priority', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'low',
                label: Text('Low'),
                icon: Icon(Icons.arrow_downward, size: 16),
              ),
              ButtonSegment(
                value: 'normal',
                label: Text('Normal'),
                icon: Icon(Icons.remove, size: 16),
              ),
              ButtonSegment(
                value: 'high',
                label: Text('High'),
                icon: Icon(Icons.arrow_upward, size: 16),
              ),
            ],
            selected: {_priority},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _priority = newSelection.first;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'pending',
                label: Text('Pending'),
                icon: Icon(Icons.schedule, size: 16),
              ),
              ButtonSegment(
                value: 'done',
                label: Text('Done'),
                icon: Icon(Icons.check_circle, size: 16),
              ),
              ButtonSegment(
                value: 'snoozed',
                label: Text('Snoozed'),
                icon: Icon(Icons.snooze, size: 16),
              ),
            ],
            selected: {_status},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _status = newSelection.first;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return FilledButton(
      onPressed: _isLoading ? null : _saveReminder,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Save & Schedule', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildEditModeButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : _deleteReminder,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD32F2F),
              side: const BorderSide(color: Color(0xFFD32F2F)),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Delete', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: _isLoading ? null : _saveReminder,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Changes', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_scheduledDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date & time first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(reminderRepositoryProvider);

      if (_isEditMode) {
        await repo.update(
          id: widget.reminderId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          categoryId: _categoryId,
          whenUtc: _scheduledDateTime!.toUtc(),
          picturePath: _photoPath,
          recurrenceRule: _recurrenceRule,
          priority: _priority,
          status: _status,
        );

        if (mounted) {
          context.pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder updated successfully')),
          );
        }
      } else {
        await repo.create(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          categoryId: _categoryId,
          whenUtc: _scheduledDateTime!.toUtc(),
          picturePath: _photoPath,
          priority: _priority,
        );

        if (mounted) {
          context.pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder created successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteReminder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this reminder?'),
        content: const Text('Deleted reminders cannot be recovered.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(reminderRepositoryProvider);
      await repo.delete(widget.reminderId!);

      if (mounted) {
        context.pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _FullScreenImageViewer extends StatefulWidget {
  final String imagePath;

  const _FullScreenImageViewer({required this.imagePath});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  final _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onDoubleTap: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(child: Image.file(File(widget.imagePath))),
        ),
      ),
    );
  }

  void _handleDoubleTap() {
    const double targetScale = 2.5;
    final Matrix4 currentTransform = _transformationController.value;
    final double currentScale = currentTransform.getMaxScaleOnAxis();

    if (currentScale > 1.5) {
      _transformationController.value = Matrix4.identity();
    } else {
      _transformationController.value = Matrix4.diagonal3Values(
        targetScale,
        targetScale,
        1.0,
      );
    }
  }
}

enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  custom;

  String get displayName {
    switch (this) {
      case RecurrenceType.none:
        return 'No Recurrence';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.custom:
        return 'Custom';
    }
  }
}
