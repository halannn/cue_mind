import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/db/app_database.dart';
import '../../../core/services/providers.dart';
import '../repositories/calendar_repository.dart';
import '../models/calendar_day.dart';

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
final dayRemindersProvider = StreamProvider.autoDispose.family<List<Reminder>, DateTime>(
  (ref, date) {
    final repo = ref.watch(calendarRepositoryProvider);
    return repo.watchDayReminders(date);
  },
);
