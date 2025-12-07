/// Calendar day data model for efficient monthly view rendering.
///
/// Contains pre-calculated density and category information for each day.
class CalendarDay {
  final DateTime date; // Normalized to midnight UTC
  final int reminderCount;
  final String? dominantCategoryColor; // Hex color if single category dominates
  final bool hasMultipleCategories;
  final bool isToday;
  final List<int> reminderIds; // For quick navigation to day detail

  const CalendarDay({
    required this.date,
    required this.reminderCount,
    this.dominantCategoryColor,
    required this.hasMultipleCategories,
    required this.isToday,
    required this.reminderIds,
  });

  /// Heatmap density level based on reminder count.
  ///
  /// Spec:
  /// - 0 reminders → none
  /// - 1-2 reminders → light
  /// - 3-5 reminders → medium
  /// - 6+ reminders → heavy
  DensityLevel get densityLevel {
    if (reminderCount == 0) return DensityLevel.none;
    if (reminderCount <= 2) return DensityLevel.light;
    if (reminderCount <= 5) return DensityLevel.medium;
    return DensityLevel.heavy;
  }

  /// Whether this day should show category background tint.
  ///
  /// Per spec: Only show if single category dominates (all reminders share it).
  bool get showCategoryBackground =>
      !hasMultipleCategories && dominantCategoryColor != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarDay &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          reminderCount == other.reminderCount &&
          dominantCategoryColor == other.dominantCategoryColor &&
          hasMultipleCategories == other.hasMultipleCategories;

  @override
  int get hashCode =>
      date.hashCode ^
      reminderCount.hashCode ^
      dominantCategoryColor.hashCode ^
      hasMultipleCategories.hashCode;
}

/// Heatmap density levels for visual indicator strength.
enum DensityLevel {
  none,   // 0 reminders
  light,  // 1-2 reminders
  medium, // 3-5 reminders
  heavy,  // 6+ reminders
}

/// Monthly calendar data container.
class MonthData {
  final DateTime month; // First day of month
  final List<CalendarDay> days; // All days in the month
  final Map<DateTime, CalendarDay> dayMap; // For O(1) lookup

  const MonthData({
    required this.month,
    required this.days,
    required this.dayMap,
  });

  /// Get calendar day for specific date, or null if not in this month.
  CalendarDay? getDayFor(DateTime date) {
    final normalized = DateTime.utc(date.year, date.month, date.day);
    return dayMap[normalized];
  }

  /// Total reminder count for the entire month.
  int get totalReminderCount =>
      days.fold(0, (sum, day) => sum + day.reminderCount);

  /// Whether this month has any reminders.
  bool get hasReminders => totalReminderCount > 0;
}
