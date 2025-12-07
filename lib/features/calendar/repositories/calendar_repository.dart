import '../../../core/services/db/app_database.dart';
import '../../../core/services/db/daos/reminder_dao.dart';
import '../../../core/services/db/daos/category_dao.dart';
import '../models/calendar_day.dart';

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
        }
      }

      final calendarDay = CalendarDay(
        date: date,
        reminderCount: dayReminders.length,
        dominantCategoryColor: dominantColor,
        hasMultipleCategories: hasMultiple,
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
}
