import '../../../core/services/db/app_database.dart';
import '../../../core/services/db/daos/reminder_dao.dart';
import '../../../core/services/db/daos/category_dao.dart';
import '../models/calendar_day.dart';
import '../models/monthly_report.dart';

/// Repository for calendar-specific data operations.
///
/// Handles monthly data aggregation, density calculation, and category highlighting.
class CalendarRepository {
  final ReminderDao reminderDao;
  final CategoryDao categoryDao;

  CalendarRepository({
    required this.reminderDao,
    required this.categoryDao,
  });

  /// Get complete month data with density and category information.
  ///
  /// This pre-calculates all calendar cell data for efficient rendering.
  Future<MonthData> getMonthData(DateTime monthUtc) async {
    // Normalize to first day of month
    final month = DateTime.utc(monthUtc.year, monthUtc.month, 1);

    // Get all reminders for the month
    final reminders = await reminderDao.getRemindersForMonth(month);

    // Get all categories for color mapping
    final categories = await categoryDao.allOnce();
    final categoryColorMap = {
      for (var cat in categories) cat.id: cat.colorHex,
    };

    // Group reminders by day
    final remindersByDay = <DateTime, List<Reminder>>{};
    for (final reminder in reminders) {
      final scheduledDate = DateTime.fromMillisecondsSinceEpoch(
        reminder.scheduledAt,
        isUtc: true,
      );
      final dayKey = DateTime.utc(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
      );
      remindersByDay.putIfAbsent(dayKey, () => []).add(reminder);
    }

    // Calculate today (UTC normalized)
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);

    // Generate calendar days for the month
    final daysInMonth = DateTime.utc(monthUtc.year, monthUtc.month + 1, 0).day;
    final days = <CalendarDay>[];
    final dayMap = <DateTime, CalendarDay>{};

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime.utc(monthUtc.year, monthUtc.month, day);
      final dayReminders = remindersByDay[date] ?? [];

      // Calculate category info
      String? dominantColor;
      bool hasMultiple = false;
  final categoryColors = <String>[];

      if (dayReminders.isNotEmpty) {
        final categoryIds = dayReminders
            .where((r) => r.categoryId != null)
            .map((r) => r.categoryId!)
            .toSet();

        if (categoryIds.length == 1) {
          // Single category dominates
          final catId = categoryIds.first;
          dominantColor = categoryColorMap[catId];
        } else if (categoryIds.length > 1) {
          hasMultiple = true;
          // Build unique category colors (limit to 4, aggregate rest omitted)
          for (final catId in categoryIds) {
            final colorHex = categoryColorMap[catId];
            if (colorHex != null) {
              categoryColors.add(colorHex);
              if (categoryColors.length >= 4) break;
            }
          }
        }
      }

      final calendarDay = CalendarDay(
        date: date,
        reminderCount: dayReminders.length,
        dominantCategoryColor: dominantColor,
        hasMultipleCategories: hasMultiple,
        categoryColors: categoryColors.isEmpty ? null : categoryColors,
        isToday: date == today,
        reminderIds: dayReminders.map((r) => r.id).toList(),
      );

      days.add(calendarDay);
      dayMap[date] = calendarDay;
    }

    return MonthData(
      month: month,
      days: days,
      dayMap: dayMap,
    );
  }

  /// Get reminders for a specific day (reactive stream).
  Stream<List<Reminder>> watchDayReminders(DateTime dayUtc) {
    final normalized = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day);
    return reminderDao.watchRemindersForDay(normalized);
  }

  /// Get reminders for a specific day (one-time fetch).
  Future<List<Reminder>> getDayReminders(DateTime dayUtc) {
    final normalized = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day);
    return reminderDao.getRemindersForDay(normalized);
  }

  // ===========================================================================
  // MONTHLY REPORT ANALYTICS
  // ===========================================================================

  /// Generate comprehensive monthly report with all analytics.
  ///
  /// Timezone-aware: Converts scheduledAt to local time before grouping.
  Future<MonthlyReport> getMonthlyReport(
    DateTime monthUtc, {
    String timezone = 'Asia/Makassar',
  }) async {
    final month = DateTime.utc(monthUtc.year, monthUtc.month, 1);

    // Debug logging
    print('🔍 [MonthlyReport] Loading report for: ${month.toIso8601String()}');

    // Get all reminders for the month
    final reminders = await reminderDao.getRemindersForMonth(month);
    final totalReminders = reminders.length;

    print('📊 [MonthlyReport] Found $totalReminders reminders for month');

    // Status breakdown
    final statusMap = await reminderDao.getMonthStatusBreakdown(month);
    print('📊 [MonthlyReport] Status breakdown: $statusMap');

    final statusBreakdown = StatusBreakdown(
      done: statusMap['done'] ?? 0,
      pending: statusMap['pending'] ?? 0,
      snoozed: statusMap['snoozed'] ?? 0,
    );

    // Category distribution
    final categoryMap = await reminderDao.getMonthCategoryDistribution(month);
    final categories = await categoryDao.allOnce();
    final categoryColorMap = {
      for (var cat in categories) cat.id: cat.colorHex,
    };
    final categoryNameMap = {
      for (var cat in categories) cat.id: cat.name,
    };

    final categoryDistribution = <CategoryDistribution>[];
    categoryMap.forEach((catId, count) {
      final percentage = totalReminders > 0 ? (count / totalReminders * 100).toDouble() : 0.0;
      categoryDistribution.add(
        CategoryDistribution(
          categoryId: catId,
          categoryName: catId == null ? 'No Category' : categoryNameMap[catId] ?? 'Unknown',
          colorHex: catId == null ? '#8E8E93' : categoryColorMap[catId] ?? '#8E8E93',
          count: count,
          percentage: percentage,
        ),
      );
    });

    // Sort by count descending
    categoryDistribution.sort((a, b) => b.count.compareTo(a.count));

    // Weekday activity
    final weekdayMap = await reminderDao.getMonthWeekdayActivity(month, timezone);
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekdayActivity = <WeekdayActivity>[];
    for (int i = 1; i <= 7; i++) {
      weekdayActivity.add(
        WeekdayActivity(
          weekday: i,
          dayName: weekdayNames[i - 1],
          count: weekdayMap[i] ?? 0,
        ),
      );
    }

    // Recurring vs one-time
    final recurringMap = await reminderDao.getMonthRecurringBreakdown(month);
    final recurringBreakdown = RecurringVsOneTime(
      recurring: recurringMap['recurring'] ?? 0,
      oneTime: recurringMap['oneTime'] ?? 0,
    );

    return MonthlyReport(
      month: month,
      totalReminders: totalReminders,
      statusBreakdown: statusBreakdown,
      categoryDistribution: categoryDistribution,
      weekdayActivity: weekdayActivity,
      recurringBreakdown: recurringBreakdown,
    );
  }
}
