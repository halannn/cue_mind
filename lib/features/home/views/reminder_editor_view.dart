import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/db/app_database.dart';
import '../../../core/services/providers.dart';
import '../../../core/utils/color_hex.dart';
import '../../../core/routes/route_config.dart';

class ReminderEditorView extends ConsumerStatefulWidget {
  final int? reminderId;
  final DateTime? initialDate;

  const ReminderEditorView({
    super.key,
    this.reminderId,
    this.initialDate,
  });

  @override
  ConsumerState<ReminderEditorView> createState() => _ReminderEditorViewState();
}

class _ReminderEditorViewState extends ConsumerState<ReminderEditorView> {
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Reminder data
  DateTime? _scheduledDateTime;
  int? _categoryId;
  String? _photoPath;

  // Recurrence state
  RecurrenceType _recurrenceType = RecurrenceType.none;
  String? _recurrenceRule;

  // UI state
  bool _isLoading = false;
  bool _isInitialized = false;

  bool get _isEditMode => widget.reminderId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadExistingReminder();
    } else {
      // Initialize with pre-filled date from calendar or default to tomorrow
      _scheduledDateTime = widget.initialDate ??
          DateTime.now().add(const Duration(days: 1));
      _isInitialized = true;
    }
  }

  /// Loads existing reminder data in edit mode.
  ///
  /// Why async in initState?
  /// - Need to fetch data from database
  /// - setState updates UI once data loaded
  /// - Loading indicator shown until complete
  Future<void> _loadExistingReminder() async {
    try {
      final dao = ref.read(reminderDaoProvider);
      final reminder = await dao.getById(widget.reminderId!);

      if (reminder == null) {
        // Reminder not found - show error and go back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder tidak ditemukan')),
          );
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
          _recurrenceType = reminder.hasRecurrence
              ? _parseRecurrenceType(reminder.recurrenceRule)
              : RecurrenceType.none;
          _recurrenceRule = reminder.recurrenceRule;
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reminder: $e')),
        );
        context.pop();
      }
    }
  }

  /// Parses recurrence rule string to enum.
  ///
  /// Why separate method?
  /// - Centralized parsing logic
  /// - Easy to extend for custom rules
  /// - Testable independently
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
    // Show loading indicator while fetching data in edit mode
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
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
          // Scrollable content
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
                    _buildDateTimePicker(),
                    const SizedBox(height: 24),
                    _buildPhotoSection(),
                  ],
                ),
              ),
            ),
          ),

          // Bottom action bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
            child: _isEditMode ? _buildEditModeButtons() : _buildCreateButton(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TITLE FIELD
  // ===========================================================================

  /// Title input field with validation.
  ///
  /// Spec requirements:
  /// - Material text field
  /// - Required
  /// - Error: "Judul harus diisi"
  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Judul',
        border: OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.sentences,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Judul harus diisi'; // ✅ Per spec
        }
        return null;
      },
    );
  }

  // ===========================================================================
  // DESCRIPTION FIELD
  // ===========================================================================

  /// Description input field.
  ///
  /// Spec requirements:
  /// - Multi-line
  /// - Grows up to 4 lines before scrolling
  /// - Optional
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Deskripsi (opsional)',
        border: OutlineInputBorder(),
      ),
      maxLines: 4, // ✅ Per spec
      textCapitalization: TextCapitalization.sentences,
    );
  }

  // ===========================================================================
  // CATEGORY SELECTOR (Color Chip)
  // ===========================================================================

  /// Category selector with color chip matching Categories feature.
  ///
  /// Design decisions:
  /// - Uses color chips for consistency with Categories view
  /// - Bottom sheet picker (not dropdown) for better mobile UX
  /// - Shows "Kelola kategori" footer per spec
  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori (opsional)', // ✅ Per spec
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

  /// Category color chip display.
  ///
  /// Why FutureBuilder?
  /// - Category might be deleted after reminder created
  /// - Need to fetch fresh data each time
  /// - Handles null case gracefully
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

  /// Shows bottom sheet category picker.
  ///
  /// Spec requirements:
  /// - Bottom sheet (not dropdown)
  /// - List of categories with color chips
  /// - "Kelola kategori" footer button
  /// - Optional: Search bar (future enhancement)
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
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Pilih Kategori',
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

              // Category list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // None option
                    ListTile(
                      leading: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFF8E8E93),
                      ),
                      title: const Text('-'),
                      trailing: _categoryId == null
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
                      onTap: () => Navigator.pop(context, -1), // -1 = clear
                    ),
                    const Divider(height: 1),

                    // Categories with color chips
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

              // ✅ Footer button per spec
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    AppRoutes.goCategories(context);
                  },
                  child: const Text('Kelola Kategori'),
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

  // ===========================================================================
  // DATE & TIME PICKER
  // ===========================================================================

  /// Date & time picker button with recurrence indicator.
  ///
  /// Spec requirements:
  /// - Main button: "Pilih tanggal & waktu"
  /// - Shows current date/time if selected
  /// - Shows recurrence summary below if set
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
                ? 'Pilih tanggal & waktu' // ✅ Per spec
                : DateFormat('EEE, d MMM yyyy • HH:mm').format(_scheduledDateTime!),
            style: const TextStyle(fontSize: 16),
          ),
        ),

        // ✅ Recurrence summary per spec
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
                  child: const Text('Ubah'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Shows date and time pickers sequentially.
  ///
  /// Why sequential?
  /// - Better mobile UX than combined picker
  /// - Matches Material Design patterns
  /// - Allows cancellation at any step
  Future<void> _showDateTimeBottomSheet() async {
    final now = DateTime.now();

    // Step 1: Pick date
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDateTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    // Step 2: Pick time
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

    // Step 3: Show recurrence option after date/time selected
    if (mounted) {
      _showRecurrenceOption();
    }
  }

  /// Shows recurrence picker bottom sheet.
  ///
  /// Spec requirements:
  /// - Options: Tidak berulang, Harian, Mingguan, Bulanan, Kustom
  /// - Modal sheet (full or half)
  /// - Updates summary instantly
  Future<void> _showRecurrenceOption() async {
    final selected = await showModalBottomSheet<RecurrenceType>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Pengulangan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),

          // ✅ All recurrence options per spec
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

  /// Converts RecurrenceType enum to iCalendar RRULE string.
  ///
  /// Format: RFC 5545 (iCalendar standard)
  /// Example: "FREQ=DAILY;INTERVAL=1"
  ///
  /// Why iCalendar format?
  /// - Industry standard
  /// - Supported by most calendar systems
  /// - Easy to parse and validate
  /// - Extensible for complex rules
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
        // TODO: Implement custom rule builder UI
        return 'FREQ=WEEKLY;INTERVAL=2'; // Example
    }
  }

  // ===========================================================================
  // PHOTO SECTION
  // ===========================================================================

  /// Photo attachment section.
  ///
  /// Spec requirements:
  /// - Before attach: "Lampirkan foto" button
  /// - After attach: 4:3 preview + "Ganti foto" + "Hapus" buttons
  /// - Tapping preview opens full-screen viewer
  Widget _buildPhotoSection() {
    if (_photoPath == null) {
      return OutlinedButton.icon(
        onPressed: _pickPhoto,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Lampirkan foto'), // ✅ Per spec
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      );
    }

    // ✅ After attach: 4:3 preview per spec
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 4:3 Image preview with tap to view
        GestureDetector(
          onTap: _showFullScreenImage,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 4 / 3, // ✅ Per spec
              child: Image.file(
                File(_photoPath!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ✅ Action buttons per spec
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Ganti foto'), // ✅ Per spec
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _photoPath = null),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus'), // ✅ Per spec
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Picks and saves photo using ImageService.
  Future<void> _pickPhoto() async {
    final img = ref.read(imageServiceProvider);
    final path = await img.pickAndSave();
    if (path != null) {
      setState(() => _photoPath = path);
    }
  }

  /// Opens full-screen zoomable image viewer.
  ///
  /// Spec requirements:
  /// - Full-screen modal viewer
  /// - Pinch to zoom
  /// - Double tap to zoom
  /// - Panning
  /// - Close with down-swipe or X icon
  void _showFullScreenImage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenImageViewer(imagePath: _photoPath!),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM ACTION BAR
  // ===========================================================================

  /// Create mode button.
  ///
  /// Spec: "Simpan & Jadwalkan"
  Widget _buildCreateButton() {
    return FilledButton(
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
          : const Text(
              'Simpan & Jadwalkan',
              style: TextStyle(fontSize: 16),
            ),
    );
  }

  /// Edit mode buttons.
  ///
  /// Spec: "Hapus" (red) + "Simpan Perubahan"
  /// Layout: 1:2 ratio (delete smaller than save)
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
            child: const Text(
              'Hapus',
              style: TextStyle(fontSize: 16),
            ),
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
                : const Text(
                    'Simpan Perubahan',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  /// Saves reminder (create or update).
  ///
  /// Validation:
  /// 1. Form validation (title required)
  /// 2. Date/time selected
  ///
  /// Flow:
  /// 1. Validate inputs
  /// 2. Call repository create/update
  /// 3. Pop with result
  /// 4. Show success message
  Future<void> _saveReminder() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Validate date/time selected
    if (_scheduledDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal & waktu terlebih dahulu'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(reminderRepositoryProvider);

      if (_isEditMode) {
        // Update existing reminder
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
        );

        if (mounted) {
          context.pop(true); // Pop with success result
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder berhasil diperbarui')),
          );
        }
      } else {
        // Create new reminder
        await repo.create(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          categoryId: _categoryId,
          whenUtc: _scheduledDateTime!.toUtc(),
          picturePath: _photoPath,
        );

        if (mounted) {
          context.pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder berhasil dibuat')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Deletes reminder with confirmation.
  ///
  /// Spec requirements:
  /// - Confirmation dialog: "Hapus pengingat ini?"
  /// - Buttons: "Hapus" (red) + "Batal"
  /// - Non-reversible warning
  Future<void> _deleteReminder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus pengingat ini?'), // ✅ Per spec
        content: const Text(
          'Pengingat yang dihapus tidak dapat dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'), // ✅ Per spec
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F), // ✅ Red per spec
            ),
            child: const Text('Hapus'), // ✅ Per spec
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
          const SnackBar(content: Text('Reminder berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// =============================================================================
// FULL SCREEN IMAGE VIEWER
// =============================================================================

/// Full-screen zoomable image viewer.
///
/// Spec requirements:
/// - Pinch to zoom (0.5x - 4x)
/// - Double tap to zoom (toggles between 1x and 2.5x)
/// - Panning
/// - Close with X icon or back button
///
/// Implementation:
/// - Uses InteractiveViewer for zoom/pan
/// - TransformationController for programmatic zoom
/// - Black background for focus
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
      backgroundColor: Colors.black, // ✅ Focus on image
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onDoubleTap: _handleDoubleTap, // ✅ Double tap zoom per spec
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5, // ✅ Zoom out limit
          maxScale: 4.0, // ✅ Zoom in limit per spec
          child: Center(
            child: Image.file(File(widget.imagePath)),
          ),
        ),
      ),
    );
  }

  /// Handles double tap to toggle zoom.
  ///
  /// Behavior:
  /// - If zoomed in (>1.5x): Reset to 1x
  /// - If at 1x: Zoom to 2.5x
  ///
  /// Why 1.5x threshold?
  /// - Accounts for minor scale variations
  /// - Prevents accidental zoom out
  void _handleDoubleTap() {
    const double targetScale = 2.5;
    final Matrix4 currentTransform = _transformationController.value;
    final double currentScale = currentTransform.getMaxScaleOnAxis();

    if (currentScale > 1.5) {
      // Zoom out to normal
      _transformationController.value = Matrix4.identity();
    } else {
      // Zoom in
      _transformationController.value = Matrix4.identity()..scale(targetScale);
    }
  }
}

// =============================================================================
// RECURRENCE TYPE ENUM
// =============================================================================

/// Recurrence type options per spec.
///
/// Spec requirements:
/// - Tidak berulang
/// - Harian
/// - Mingguan
/// - Bulanan
/// - Kustom
enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  custom;

  String get displayName {
    switch (this) {
      case RecurrenceType.none:
        return 'Tidak berulang';
      case RecurrenceType.daily:
        return 'Harian';
      case RecurrenceType.weekly:
        return 'Mingguan';
      case RecurrenceType.monthly:
        return 'Bulanan';
      case RecurrenceType.custom:
        return 'Kustom';
    }
  }
}
