import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/db/app_database.dart';
import '../../../core/services/providers.dart';
import '../services/reminder_repository.dart';

class HomeState {
  final AsyncValue<List<Reminder>> upcoming; // 48h default
  final String? error;
  const HomeState({this.upcoming = const AsyncValue.loading(), this.error});

  HomeState copyWith({AsyncValue<List<Reminder>>? upcoming, String? error}) =>
      HomeState(upcoming: upcoming ?? this.upcoming, error: error);
}

class HomeVM extends Notifier<HomeState> {
  StreamSubscription<List<Reminder>>? _sub;
  ReminderRepository get _repo => ref.read(reminderRepositoryProvider);

  @override
  HomeState build() {
    state = const HomeState(upcoming: AsyncValue.loading());
    _sub?.cancel();
    _sub = _repo.watchUpcoming(hours: 48).listen(
      (data) => state = state.copyWith(upcoming: AsyncValue.data(data)),
      onError: (e, st) => state = state.copyWith(upcoming: AsyncValue.error(e, st)),
    );
    ref.onDispose(() => _sub?.cancel());
    return state;
  }

  Future<void> markDone(int id) => _repo.markDone(id);

  Future<void> snooze(int id, Duration dur) => _repo.snooze(id, dur);

  Future<void> delete(int id) => _repo.delete(id);
}

final homeVMProvider = NotifierProvider<HomeVM, HomeState>(HomeVM.new);
