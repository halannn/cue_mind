import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../viewmodels/calendar_viewmodel.dart';
import '../models/calendar_day.dart';
import '../widgets/today_reminders_section.dart';
import '../../../core/routes/route_config.dart';

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
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Monthly Report',
            onPressed: () => context.push('/calendar/report'),
          ),

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
        _buildMonthHeader(context, vm, selectedMonth),

        const Divider(height: 1),

        _buildDayOfWeekLabels(context),

        GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! < 0) {
              vm.nextMonth();
            } else if (details.primaryVelocity! > 0) {
              vm.previousMonth();
            }
          },
          child: _buildCalendarGrid(context, ref, monthData),
        ),

        const Divider(height: 1),

        const Expanded(child: TodayRemindersSection()),
      ],
    );
  }

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
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: vm.previousMonth,
            tooltip: 'Previous month',
          ),

          Text(
            DateFormat.yMMMM().format(month),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),

          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: vm.nextMonth,
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }

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
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
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

  Widget _buildCalendarGrid(
    BuildContext context,
    WidgetRef ref,
    MonthData monthData,
  ) {
    final firstDay = monthData.month;
    final firstWeekday = firstDay.weekday;
    final daysInMonth = monthData.days.length;

    final leadingEmptyCells = firstWeekday - 1;
    final totalCells = leadingEmptyCells + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.85,
      ),
      itemCount: rows * 7,
      itemBuilder: (context, index) {
        final dayIndex = index - leadingEmptyCells;

        if (dayIndex < 0 || dayIndex >= daysInMonth) {
          return const SizedBox.shrink();
        }

        final calendarDay = monthData.days[dayIndex];
        return _buildDayCell(context, ref, calendarDay);
      },
    );
  }

  Widget _buildDayCell(BuildContext context, WidgetRef ref, CalendarDay day) {
    final theme = Theme.of(context);

    Color? categoryColor;
    if (day.showCategoryBackground && day.dominantCategoryColor != null) {
      try {
        final hex = day.dominantCategoryColor!.replaceFirst('#', '');
        categoryColor = Color(int.parse('0xFF$hex'));
      } catch (_) {}
    }

    final backgroundColor = categoryColor != null
        ? categoryColor.withValues(alpha: 0.12)
        : Colors.transparent;

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
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Stack(
          children: [
            if (day.hasMultipleCategories &&
                (day.categoryColors ?? const []).isNotEmpty)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: (day.categoryColors ?? const []).map((hex) {
                      Color segColor;
                      try {
                        final clean = hex.replaceFirst('#', '');
                        segColor = Color(int.parse('0xFF$clean'));
                      } catch (_) {
                        segColor = theme.colorScheme.surfaceTint;
                      }
                      return Expanded(child: Container(color: segColor));
                    }).toList(),
                  ),
                ),
              ),

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
          color: theme.colorScheme.primary.withValues(alpha: opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  void _onDayTap(BuildContext context, WidgetRef ref, CalendarDay day) {
    context.push('/calendar/day/${day.date.toIso8601String()}');
  }

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

                context.push(
                  '${AppRoutes.reminderNew}?date=${day.date.toIso8601String()}',
                );
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
