import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../viewmodels/calendar_viewmodel.dart';
import '../models/calendar_day.dart';
import '../../../core/routes/route_config.dart';

/// Calendar feature main view - Monthly grid with heatmap indicators.
///
/// Spec implementation:
/// - Monthly calendar grid (7x5 or 7x6)
/// - Heatmap density indicators (count-based)
/// - Category background highlights
/// - Swipe gestures for month navigation
/// - Today indicator
/// - Tap to open day detail
/// - Long-press for quick add
class CalendarView extends ConsumerWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmState = ref.watch(calendarVMProvider);
    final vm = ref.read(calendarVMProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        elevation: 0,
        actions: [
          // Jump to today button
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to today',
            onPressed: vm.goToToday,
          ),
        ],
      ),
      body: vmState.monthData.when(
        data: (monthData) => _buildCalendarContent(
          context,
          ref,
          vm,
          vmState.selectedMonth,
          monthData,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading calendar: $error'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(calendarVMProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.reminderNew),
        tooltip: 'Add reminder',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendarContent(
    BuildContext context,
    WidgetRef ref,
    CalendarVM vm,
    DateTime selectedMonth,
    MonthData monthData,
  ) {
    return Column(
      children: [
        // Month header with navigation
        _buildMonthHeader(context, vm, selectedMonth),

        const Divider(height: 1),

        // Day of week labels
        _buildDayOfWeekLabels(context),

        // Calendar grid
        Expanded(
          child: GestureDetector(
            // Swipe gestures for month navigation
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! < 0) {
                // Swipe left -> next month
                vm.nextMonth();
              } else if (details.primaryVelocity! > 0) {
                // Swipe right -> previous month
                vm.previousMonth();
              }
            },
            child: _buildCalendarGrid(context, ref, monthData),
          ),
        ),

        // Empty state message if no reminders this month
        if (!monthData.hasReminders)
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'No plans this month yet.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start by adding your first reminder.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Month header: [ < ] May 2025 [ > ]
  Widget _buildMonthHeader(
    BuildContext context,
    CalendarVM vm,
    DateTime month,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous month button
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: vm.previousMonth,
            tooltip: 'Previous month',
          ),

          // Month-year label
          Text(
            DateFormat.yMMMM().format(month),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          // Next month button
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: vm.nextMonth,
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }

  /// Day of week labels: Mon Tue Wed Thu Fri Sat Sun
  Widget _buildDayOfWeekLabels(BuildContext context) {
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: weekDays.map((day) {
          final isWeekend = day == 'Sat' || day == 'Sun';
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isWeekend
                      ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Calendar grid - builds 7-column grid with proper padding
  Widget _buildCalendarGrid(
    BuildContext context,
    WidgetRef ref,
    MonthData monthData,
  ) {
    // Calculate grid layout
    final firstDay = monthData.month;
    final firstWeekday = firstDay.weekday; // 1 = Monday, 7 = Sunday
    final daysInMonth = monthData.days.length;

    // Calculate total cells needed (include leading empty cells)
    final leadingEmptyCells = firstWeekday - 1;
    final totalCells = leadingEmptyCells + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.85, // Slightly taller than wide
      ),
      itemCount: rows * 7,
      itemBuilder: (context, index) {
        // Calculate day number
        final dayIndex = index - leadingEmptyCells;

        // Empty cell before month starts
        if (dayIndex < 0 || dayIndex >= daysInMonth) {
          return const SizedBox.shrink();
        }

        final calendarDay = monthData.days[dayIndex];
        return _buildDayCell(context, ref, calendarDay);
      },
    );
  }

  /// Individual day cell with heatmap indicator and category background
  Widget _buildDayCell(
    BuildContext context,
    WidgetRef ref,
    CalendarDay day,
  ) {
    final theme = Theme.of(context);

    // Parse category color if present
    Color? categoryColor;
    if (day.showCategoryBackground && day.dominantCategoryColor != null) {
      try {
        final hex = day.dominantCategoryColor!.replaceFirst('#', '');
        categoryColor = Color(int.parse('0xFF$hex'));
      } catch (_) {
        // Invalid color, ignore
      }
    }

    // Background color: category tint or transparent
    final backgroundColor = categoryColor != null
        ? categoryColor.withOpacity(0.12)
        : Colors.transparent;

    // Today indicator
    final isToday = day.isToday;

    return InkWell(
      onTap: () => _onDayTap(context, ref, day),
      onLongPress: () => _onDayLongPress(context, ref, day),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Date number
            Center(
              child: Text(
                '${day.date.day}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),

            // Heatmap density indicator (bottom)
            if (day.reminderCount > 0)
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: _buildDensityIndicator(theme, day.densityLevel),
              ),
          ],
        ),
      ),
    );
  }

  /// Heatmap density indicator - visual strength based on count
  Widget _buildDensityIndicator(ThemeData theme, DensityLevel level) {
    double opacity;
    switch (level) {
      case DensityLevel.none:
        return const SizedBox.shrink();
      case DensityLevel.light:
        opacity = 0.3;
        break;
      case DensityLevel.medium:
        opacity = 0.6;
        break;
      case DensityLevel.heavy:
        opacity = 0.9;
        break;
    }

    return Center(
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// Handle day tap - navigate to day detail view
  void _onDayTap(BuildContext context, WidgetRef ref, CalendarDay day) {
    // Navigate to day detail screen
    context.push('/calendar/day/${day.date.toIso8601String()}');
  }

  /// Handle day long-press - show quick add menu
  void _onDayLongPress(BuildContext context, WidgetRef ref, CalendarDay day) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              DateFormat.yMMMMd().format(day.date),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to reminder editor with date pre-filled
                context.push('${AppRoutes.reminderNew}?date=${day.date.toIso8601String()}');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add reminder on this day'),
            ),
            if (day.reminderCount > 0) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/calendar/day/${day.date.toIso8601String()}');
                },
                icon: const Icon(Icons.event),
                label: Text('View reminders (${day.reminderCount})'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
