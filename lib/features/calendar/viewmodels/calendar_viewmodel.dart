import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/db/app_database.dart';
import '../../../core/services/providers.dart';
import '../repositories/calendar_repository.dart';
import '../models/calendar_day.dart';
import '../models/monthly_report.dart';

// ============================================================================
// PROVIDERS
// ============================================================================

/// Calendar repository provider.
final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository(
    reminderDao: ref.watch(reminderDaoProvider),
    categoryDao: ref.watch(categoryDaoProvider),
  );
});

/// Simple state holder for selected month.
class CalendarState {
  final DateTime selectedMonth;
  final AsyncValue<MonthData> monthData;

  CalendarState({
    required this.selectedMonth,
    this.monthData = const AsyncValue.loading(),
  });

  CalendarState copyWith({
    DateTime? selectedMonth,
    AsyncValue<MonthData>? monthData,
  }) {
    return CalendarState(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      monthData: monthData ?? this.monthData,
    );
  }
}

/// Calendar view model using Notifier pattern.
class CalendarVM extends Notifier<CalendarState> {
  CalendarRepository get _repo => ref.read(calendarRepositoryProvider);

  @override
  CalendarState build() {
    final now = DateTime.now().toUtc();
    final initialMonth = DateTime.utc(now.year, now.month, 1);

    // Initialize and load first month
    state = CalendarState(selectedMonth: initialMonth);
    _loadMonthData(initialMonth);

    return state;
  }

  Future<void> _loadMonthData(DateTime month) async {
    state = state.copyWith(monthData: const AsyncValue.loading());

    try {
      final data = await _repo.getMonthData(month);
      state = state.copyWith(monthData: AsyncValue.data(data));
    } catch (error, stackTrace) {
      state = state.copyWith(
        monthData: AsyncValue.error(error, stackTrace),
      );
    }
  }

  void previousMonth() {
    final previous = DateTime.utc(
      state.selectedMonth.year,
      state.selectedMonth.month - 1,
      1,
    );
    state = state.copyWith(selectedMonth: previous);
    _loadMonthData(previous);
  }

  void nextMonth() {
    final next = DateTime.utc(
      state.selectedMonth.year,
      state.selectedMonth.month + 1,
      1,
    );
    state = state.copyWith(selectedMonth: next);
    _loadMonthData(next);
  }

  void goToMonth(DateTime month) {
    final normalized = DateTime.utc(month.year, month.month, 1);
    state = state.copyWith(selectedMonth: normalized);
    _loadMonthData(normalized);
  }

  void goToToday() {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, 1);
    state = state.copyWith(selectedMonth: today);
    _loadMonthData(today);
  }
}

/// Calendar view model provider.
final calendarVMProvider = NotifierProvider<CalendarVM, CalendarState>(
  CalendarVM.new,
);

/// Day reminders stream provider (for day detail view).
final dayRemindersProvider =
    StreamProvider.autoDispose.family<List<Reminder>, DateTime>(
  (ref, date) {
    final repo = ref.watch(calendarRepositoryProvider);
    return repo.watchDayReminders(date);
  },
);

// ============================================================================
// MONTHLY REPORT PROVIDERS
// ============================================================================

/// Monthly report provider with auto-refresh.
final monthlyReportProvider =
    FutureProvider.autoDispose.family<MonthlyReport, DateTime>(
  (ref, month) {
    final repo = ref.watch(calendarRepositoryProvider);
    return repo.getMonthlyReport(month);
  },
);

/// Monthly report state holder for navigation.
class MonthlyReportState {
  final DateTime selectedMonth;
  final AsyncValue<MonthlyReport> reportData;

  MonthlyReportState({
    required this.selectedMonth,
    this.reportData = const AsyncValue.loading(),
  });

  MonthlyReportState copyWith({
    DateTime? selectedMonth,
    AsyncValue<MonthlyReport>? reportData,
  }) {
    return MonthlyReportState(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      reportData: reportData ?? this.reportData,
    );
  }
}

/// Monthly report view model.
class MonthlyReportVM extends Notifier<MonthlyReportState> {
  CalendarRepository get _repo => ref.read(calendarRepositoryProvider);

  @override
  MonthlyReportState build() {
    final now = DateTime.now().toUtc();
    final initialMonth = DateTime.utc(now.year, now.month, 1);

    state = MonthlyReportState(selectedMonth: initialMonth);
    _loadReportData(initialMonth);

    return state;
  }

  Future<void> _loadReportData(DateTime month) async {
    state = state.copyWith(reportData: const AsyncValue.loading());

    try {
      final data = await _repo.getMonthlyReport(month);
      state = state.copyWith(reportData: AsyncValue.data(data));
    } catch (error, stackTrace) {
      state = state.copyWith(
        reportData: AsyncValue.error(error, stackTrace),
      );
    }
  }

  void previousMonth() {
    final previous = DateTime.utc(
      state.selectedMonth.year,
      state.selectedMonth.month - 1,
      1,
    );
    state = state.copyWith(selectedMonth: previous);
    _loadReportData(previous);
  }

  void nextMonth() {
    final next = DateTime.utc(
      state.selectedMonth.year,
      state.selectedMonth.month + 1,
      1,
    );
    state = state.copyWith(selectedMonth: next);
    _loadReportData(next);
  }

  void goToMonth(DateTime month) {
    final normalized = DateTime.utc(month.year, month.month, 1);
    state = state.copyWith(selectedMonth: normalized);
    _loadReportData(normalized);
  }
}

/// Monthly report view model provider.
final monthlyReportVMProvider =
    NotifierProvider<MonthlyReportVM, MonthlyReportState>(
  MonthlyReportVM.new,
);
