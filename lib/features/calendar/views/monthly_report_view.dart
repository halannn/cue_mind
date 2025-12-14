import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../viewmodels/calendar_viewmodel.dart';
import '../models/monthly_report.dart';
import '../../../core/utils/color_hex.dart';

class MonthlyReportView extends ConsumerWidget {
  const MonthlyReportView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmState = ref.watch(monthlyReportVMProvider);
    final vm = ref.read(monthlyReportVMProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(_formatMonthTitle(vmState.selectedMonth)),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildMonthNavigationHeader(context, vm, vmState.selectedMonth),

          const Divider(height: 1),

          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! < 0) {
                  vm.nextMonth();
                } else if (details.primaryVelocity! > 0) {
                  vm.previousMonth();
                }
              },
              child: vmState.reportData.when(
                data: (report) {
                  debugPrint(
                    '🔍 [View] Report month: ${report.month.year}-${report.month.month}',
                  );
                  debugPrint(
                    '🔍 [View] Selected month: ${vmState.selectedMonth.year}-${vmState.selectedMonth.month}',
                  );

                  if (report.month.year != vmState.selectedMonth.year ||
                      report.month.month != vmState.selectedMonth.month) {
                    debugPrint(
                      '⚠️ [View] Data mismatch detected, showing loading',
                    );
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _buildReportContent(context, report);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorState(context, error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMonthTitle(DateTime month) {
    return 'Monthly Summary';
  }

  Widget _buildReportContent(BuildContext context, MonthlyReport report) {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    if (report.month.isAfter(currentMonthStart)) {
      return _buildFutureMonthState(context, report.month);
    }

    if (!report.hasData) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTotalRemindersCard(context, report),

          const SizedBox(height: 16),

          _buildStatusBreakdownCard(context, report.statusBreakdown),

          const SizedBox(height: 16),

          _buildCategoryDistributionCard(context, report.categoryDistribution),

          const SizedBox(height: 16),

          _buildWeekdayActivityCard(context, report.weekdayActivity),

          const SizedBox(height: 16),

          _buildRecurringBreakdownCard(context, report.recurringBreakdown),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_chart_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No reminders this month.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enjoy your free time 🌿',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/calendar'),
              icon: const Icon(Icons.calendar_month),
              label: const Text('Go to Calendar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFutureMonthState(BuildContext context, DateTime month) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Nothing planned for ${DateFormat.MMMM().format(month)} yet.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your future is wide open ✨',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading report',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavigationHeader(
    BuildContext context,
    MonthlyReportVM vm,
    DateTime month,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: vm.previousMonth,
            tooltip: 'Previous month',
            iconSize: 28,
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
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRemindersCard(BuildContext context, MonthlyReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              '${report.totalReminders}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reminders scheduled this month',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBreakdownCard(
    BuildContext context,
    StatusBreakdown breakdown,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Overview',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),

            Center(
              child: SizedBox(
                width: 180,
                height: 180,
                child: CustomPaint(painter: DonutChartPainter(breakdown)),
              ),
            ),

            const SizedBox(height: 24),

            _buildStatusLegend(context, breakdown),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      breakdown.insightMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLegend(BuildContext context, StatusBreakdown breakdown) {
    return Column(
      children: [
        _buildLegendItem(
          context,
          color: Colors.green,
          label: 'Done',
          count: breakdown.done,
          percentage: breakdown.donePercentage,
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          context,
          color: Colors.blue,
          label: 'Pending',
          count: breakdown.pending,
          percentage: breakdown.pendingPercentage,
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          context,
          color: Colors.amber,
          label: 'Snoozed',
          count: breakdown.snoozed,
          percentage: breakdown.snoozedPercentage,
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
    required int count,
    required double percentage,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          '$count (${percentage.toStringAsFixed(0)}%)',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildCategoryDistributionCard(
    BuildContext context,
    List<CategoryDistribution> distribution,
  ) {
    if (distribution.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Distribution',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            ...distribution.map(
              (cat) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCategoryBar(context, cat),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar(BuildContext context, CategoryDistribution cat) {
    Color barColor;
    try {
      barColor = cat.colorHex.toColor();
    } catch (_) {
      barColor = Colors.grey;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                cat.categoryName,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${cat.percentage.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: cat.percentage / 100,
            minHeight: 8,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayActivityCard(
    BuildContext context,
    List<WeekdayActivity> activity,
  ) {
    final maxCount = activity
        .map((a) => a.count)
        .reduce((a, b) => a > b ? a : b);
    final busiestDay = activity.reduce((a, b) => a.count > b.count ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Busiest Days of the Week',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 170,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: activity.map((day) {
                  return _buildWeekdayBar(
                    context,
                    day,
                    day.getNormalizedHeight(maxCount),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            if (maxCount > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${busiestDay.dayName}s are your busiest days.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayBar(
    BuildContext context,
    WeekdayActivity day,
    double normalizedHeight,
  ) {
    final isWeekend = day.weekday >= 6;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (day.count > 0)
              Text(
                '${day.count}',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 2),

            Container(
              width: double.infinity,
              height: normalizedHeight * 120,
              decoration: BoxDecoration(
                color: isWeekend
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.5)
                    : Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              day.dayName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isWeekend
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringBreakdownCard(
    BuildContext context,
    RecurringVsOneTime breakdown,
  ) {
    if (breakdown.total == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Routine vs Spontaneity',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  if (breakdown.recurring > 0)
                    Expanded(
                      flex: breakdown.recurring,
                      child: Container(
                        height: 40,
                        color: Theme.of(context).colorScheme.primary,
                        alignment: Alignment.center,
                        child: Text(
                          '${breakdown.recurringPercentage.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  if (breakdown.oneTime > 0)
                    Expanded(
                      flex: breakdown.oneTime,
                      child: Container(
                        height: 40,
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.7),
                        alignment: Alignment.center,
                        child: Text(
                          '${breakdown.oneTimePercentage.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                _buildRecurringLegendItem(
                  context,
                  color: Theme.of(context).colorScheme.primary,
                  label: 'Recurring',
                  count: breakdown.recurring,
                ),
                const SizedBox(width: 24),
                _buildRecurringLegendItem(
                  context,
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.7),
                  label: 'One-time',
                  count: breakdown.oneTime,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      breakdown.insightMessage,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
    required int count,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text('$label ($count)', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final StatusBreakdown breakdown;

  DonutChartPainter(this.breakdown);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.6;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final total = breakdown.total;
    if (total == 0) return;

    final doneAngle = (breakdown.done / total) * 2 * math.pi;
    final pendingAngle = (breakdown.pending / total) * 2 * math.pi;
    final snoozedAngle = (breakdown.snoozed / total) * 2 * math.pi;

    var startAngle = -math.pi / 2;

    if (breakdown.done > 0) {
      final paint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - innerRadius;

      canvas.drawArc(rect, startAngle, doneAngle, false, paint);
      startAngle += doneAngle;
    }

    if (breakdown.pending > 0) {
      final paint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - innerRadius;

      canvas.drawArc(rect, startAngle, pendingAngle, false, paint);
      startAngle += pendingAngle;
    }

    if (breakdown.snoozed > 0) {
      final paint = Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius - innerRadius;

      canvas.drawArc(rect, startAngle, snoozedAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
