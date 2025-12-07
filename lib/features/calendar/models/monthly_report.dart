/// Monthly report data models for reflective analytics.
///
/// Design philosophy:
/// - Non-judgmental (no "failure" metrics)
/// - Reflective, not prescriptive
/// - Emotionally safe
class MonthlyReport {
  final DateTime month; // First day of month
  final int totalReminders;
  final StatusBreakdown statusBreakdown;
  final List<CategoryDistribution> categoryDistribution;
  final List<WeekdayActivity> weekdayActivity;
  final RecurringVsOneTime recurringBreakdown;

  const MonthlyReport({
    required this.month,
    required this.totalReminders,
    required this.statusBreakdown,
    required this.categoryDistribution,
    required this.weekdayActivity,
    required this.recurringBreakdown,
  });

  /// Whether this month has any data to show.
  bool get hasData => totalReminders > 0;

  /// Whether this month is in the future.
  bool get isFutureMonth {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    return month.isAfter(thisMonth);
  }
}

/// Status breakdown for donut chart.
class StatusBreakdown {
  final int done;
  final int pending;
  final int snoozed;

  const StatusBreakdown({
    required this.done,
    required this.pending,
    required this.snoozed,
  });

  int get total => done + pending + snoozed;

  double get donePercentage => total > 0 ? (done / total * 100) : 0;
  double get pendingPercentage => total > 0 ? (pending / total * 100) : 0;
  double get snoozedPercentage => total > 0 ? (snoozed / total * 100) : 0;

  /// Dominant status for micro-insight text.
  String get dominantStatus {
    if (done >= pending && done >= snoozed) return 'done';
    if (pending >= snoozed) return 'pending';
    return 'snoozed';
  }

  /// Emotionally safe insight message.
  String get insightMessage {
    if (total == 0) return 'No reminders this month.';

    switch (dominantStatus) {
      case 'done':
        return 'Most of your reminders were completed. 🎉';
      case 'pending':
        return 'You have several reminders to focus on.';
      case 'snoozed':
        return 'You adjusted your schedule thoughtfully.';
      default:
        return '';
    }
  }
}

/// Category distribution for horizontal bar chart.
class CategoryDistribution {
  final int? categoryId;
  final String categoryName;
  final String colorHex;
  final int count;
  final double percentage;

  const CategoryDistribution({
    this.categoryId,
    required this.categoryName,
    required this.colorHex,
    required this.count,
    required this.percentage,
  });
}

/// Weekday activity for vertical bar chart.
class WeekdayActivity {
  final int weekday; // 1 = Monday, 7 = Sunday
  final String dayName;
  final int count;

  const WeekdayActivity({
    required this.weekday,
    required this.dayName,
    required this.count,
  });

  /// Get normalized height for chart (0.0 to 1.0).
  double getNormalizedHeight(int maxCount) {
    if (maxCount == 0) return 0.0;
    return count / maxCount;
  }
}

/// Recurring vs one-time split.
class RecurringVsOneTime {
  final int recurring;
  final int oneTime;

  const RecurringVsOneTime({
    required this.recurring,
    required this.oneTime,
  });

  int get total => recurring + oneTime;

  double get recurringPercentage => total > 0 ? (recurring / total * 100) : 0;
  double get oneTimePercentage => total > 0 ? (oneTime / total * 100) : 0;

  /// Insight about routine vs spontaneity.
  String get insightMessage {
    if (total == 0) return '';

    if (recurringPercentage >= 60) {
      return 'You have strong routines this month. 🔄';
    } else if (oneTimePercentage >= 60) {
      return 'Your schedule is flexible and adaptive. ✨';
    } else {
      return 'You balance routine and spontaneity well. ⚖️';
    }
  }
}
