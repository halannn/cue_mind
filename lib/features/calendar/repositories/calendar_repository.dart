import 'package:flutter/foundation.dart';
import '../../../core/services/db/app_database.dart';
import '../../../core/services/db/daos/reminder_dao.dart';
import '../../../core/services/db/daos/category_dao.dart';
import '../models/calendar_day.dart';
import '../models/monthly_report.dart';

class CalendarRepository {
  final ReminderDao reminderDao;
  final CategoryDao categoryDao;

  CalendarRepository({required this.reminderDao, required this.categoryDao});

  Future<MonthData> getMonthData(DateTime monthLocal) async {
    final month = DateTime(monthLocal.year, monthLocal.month, 1);

    final reminders = await reminderDao.getRemindersForMonth(month);

    final categories = await categoryDao.allOnce();
    final categoryColorMap = {for (var cat in categories) cat.id: cat.colorHex};

    final remindersByDay = <DateTime, List<Reminder>>{};
    for (final reminder in reminders) {
      final scheduledDate = DateTime.fromMillisecondsSinceEpoch(
        reminder.scheduledAt,
        isUtc: true,
      ).toLocal();
      final dayKey = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
      );
      remindersByDay.putIfAbsent(dayKey, () => []).add(reminder);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final daysInMonth = DateTime(monthLocal.year, monthLocal.month + 1, 0).day;
    final days = <CalendarDay>[];
    final dayMap = <DateTime, CalendarDay>{};

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(monthLocal.year, monthLocal.month, day);
      final dayReminders = remindersByDay[date] ?? [];

      String? dominantColor;
      bool hasMultiple = false;
      final categoryColors = <String>[];

      if (dayReminders.isNotEmpty) {
        final categoryIds = dayReminders
            .where((r) => r.categoryId != null)
            .map((r) => r.categoryId!)
            .toSet();

        if (categoryIds.length == 1) {
          final catId = categoryIds.first;
          dominantColor = categoryColorMap[catId];
        } else if (categoryIds.length > 1) {
          hasMultiple = true;

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

    return MonthData(month: month, days: days, dayMap: dayMap);
  }

  Stream<List<Reminder>> watchDayReminders(DateTime dayLocal) {
    final normalized = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
    return reminderDao.watchRemindersForDay(normalized);
  }

  Future<List<Reminder>> getDayReminders(DateTime dayLocal) {
    final normalized = DateTime(dayLocal.year, dayLocal.month, dayLocal.day);
    return reminderDao.getRemindersForDay(normalized);
  }

  Future<MonthlyReport> getMonthlyReport(
    DateTime monthLocal, {
    String timezone = 'Asia/Makassar',
  }) async {
    final month = DateTime(monthLocal.year, monthLocal.month, 1);

    debugPrint(
      '🔍 [MonthlyReport] Loading report for: ${month.toIso8601String()}',
    );

    final reminders = await reminderDao.getRemindersForMonth(month);
    final totalReminders = reminders.length;

    debugPrint('📊 [MonthlyReport] Found $totalReminders reminders for month');

    final statusMap = await reminderDao.getMonthStatusBreakdown(month);
    debugPrint('📊 [MonthlyReport] Status breakdown: $statusMap');

    final statusBreakdown = StatusBreakdown(
      done: statusMap['done'] ?? 0,
      pending: statusMap['pending'] ?? 0,
      snoozed: statusMap['snoozed'] ?? 0,
    );

    final categoryMap = await reminderDao.getMonthCategoryDistribution(month);
    final categories = await categoryDao.allOnce();
    final categoryColorMap = {for (var cat in categories) cat.id: cat.colorHex};
    final categoryNameMap = {for (var cat in categories) cat.id: cat.name};

    final categoryDistribution = <CategoryDistribution>[];
    categoryMap.forEach((catId, count) {
      final percentage = totalReminders > 0
          ? (count / totalReminders * 100).toDouble()
          : 0.0;
      categoryDistribution.add(
        CategoryDistribution(
          categoryId: catId,
          categoryName: catId == null
              ? 'No Category'
              : categoryNameMap[catId] ?? 'Unknown',
          colorHex: catId == null
              ? '#8E8E93'
              : categoryColorMap[catId] ?? '#8E8E93',
          count: count,
          percentage: percentage,
        ),
      );
    });

    categoryDistribution.sort((a, b) => b.count.compareTo(a.count));

    final weekdayMap = await reminderDao.getMonthWeekdayActivity(month);
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
