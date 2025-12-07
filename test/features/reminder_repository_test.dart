import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cue_mind/core/services/db/app_database.dart';
import 'package:cue_mind/core/services/db/daos/reminder_dao.dart';
import 'package:cue_mind/core/services/notification_service.dart';
import 'package:cue_mind/features/home/services/reminder_repository.dart';

// Manual mocks for testing
class MockAppDatabase extends AppDatabase {
  @override
  int get schemaVersion => 1;
}

class MockReminderDao implements ReminderDao {
  int insertCallCount = 0;
  int updateCallCount = 0;
  int markDoneCallCount = 0;
  int snoozeToCallCount = 0;
  int softDeleteCallCount = 0;

  Exception? insertException;
  int insertResult = 1;

  @override
  Future<int> insert(RemindersCompanion data) async {
    insertCallCount++;
    if (insertException != null) throw insertException!;
    return insertResult;
  }

  @override
  Future<int> updateById(int id, RemindersCompanion data) async {
    updateCallCount++;
    return 1;
  }

  @override
  Future<int> markDone(int id) async {
    markDoneCallCount++;
    return 1;
  }

  @override
  Future<int> snoozeTo(int id, int whenMillis) async {
    snoozeToCallCount++;
    return 1;
  }

  @override
  Future<int> softDelete(int id) async {
    softDeleteCallCount++;
    return 1;
  }

  @override
  Stream<List<Reminder>> watchUpcomingHours({int hours = 48}) {
    return Stream.value([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockNotificationService implements NotificationService {
  int scheduleCallCount = 0;
  int cancelCallCount = 0;

  @override
  Future<void> scheduleExact({
    required int id,
    required String title,
    required String body,
    required DateTime fireTimeUtc,
  }) async {
    scheduleCallCount++;
  }

  @override
  Future<void> cancel(int id) async {
    cancelCallCount++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Reminder Repository Tests', () {
    late MockAppDatabase mockDb;
    late MockReminderDao mockDao;
    late MockNotificationService mockNotifService;
    late ReminderRepository repository;

    setUp(() {
      // Arrange - Initialize mocks and repository
      mockDb = MockAppDatabase();
      mockDao = MockReminderDao();
      mockNotifService = MockNotificationService();
      repository = ReminderRepository(
        db: mockDb,
        dao: mockDao,
        notif: mockNotifService,
      );
    });

    test('should create reminder successfully and schedule notification', () async {
      // Arrange
      const reminderId = 1;
      const title = 'Test Reminder';
      final whenUtc = DateTime.utc(2025, 12, 10, 10, 0);
      mockDao.insertResult = reminderId;

      // Act
      final result = await repository.create(
        title: title,
        whenUtc: whenUtc,
      );

      // Assert
      expect(result, reminderId);
      expect(mockDao.insertCallCount, 1);
      expect(mockNotifService.scheduleCallCount, 1);
    });

    test('should create reminder with all optional fields provided', () async {
      // Arrange
      const reminderId = 2;
      const title = 'Complete Reminder';
      const description = 'Test Description';
      const categoryId = 5;
      const picturePath = '/path/to/picture.jpg';
      final whenUtc = DateTime.utc(2025, 12, 15, 14, 30);
      mockDao.insertResult = reminderId;

      // Act
      final result = await repository.create(
        title: title,
        description: description,
        categoryId: categoryId,
        whenUtc: whenUtc,
        picturePath: picturePath,
      );

      // Assert
      expect(result, reminderId);
      expect(mockDao.insertCallCount, 1);
      expect(mockNotifService.scheduleCallCount, 1);
    });

    test('should mark reminder as done and cancel its notification', () async {
      // Arrange
      const reminderId = 3;

      // Act
      await repository.markDone(reminderId);

      // Assert
      expect(mockDao.markDoneCallCount, 1);
      expect(mockNotifService.cancelCallCount, 1);
    });

    test('should snooze reminder and reschedule notification correctly', () async {
      // Arrange
      const reminderId = 4;
      final duration = Duration(minutes: 10);

      // Act
      await repository.snooze(reminderId, duration);

      // Assert
      expect(mockDao.snoozeToCallCount, 1);
      expect(mockNotifService.cancelCallCount, 1);
      expect(mockNotifService.scheduleCallCount, 1);
    });

    test('should perform soft delete on reminder and cancel notification', () async {
      // Arrange
      const reminderId = 5;

      // Act
      await repository.delete(reminderId);

      // Assert
      expect(mockDao.softDeleteCallCount, 1);
      expect(mockNotifService.cancelCallCount, 1);
    });

    test('should update reminder without recurrence rule successfully', () async {
      // Arrange
      const reminderId = 6;
      const title = 'Updated Reminder';
      final whenUtc = DateTime.utc(2025, 12, 20, 16, 0);

      // Act
      await repository.update(
        id: reminderId,
        title: title,
        whenUtc: whenUtc,
      );

      // Assert
      expect(mockDao.updateCallCount, 1);
      expect(mockNotifService.cancelCallCount, 1);
      expect(mockNotifService.scheduleCallCount, 1);
    });

    test('should update reminder with recurrence rule correctly', () async {
      // Arrange
      const reminderId = 7;
      const title = 'Recurring Reminder';
      const recurrenceRule = 'FREQ=DAILY;INTERVAL=1';
      final whenUtc = DateTime.utc(2025, 12, 25, 9, 0);

      // Act
      await repository.update(
        id: reminderId,
        title: title,
        whenUtc: whenUtc,
        recurrenceRule: recurrenceRule,
      );

      // Assert
      expect(mockDao.updateCallCount, 1);
      expect(mockNotifService.cancelCallCount, 1);
      expect(mockNotifService.scheduleCallCount, 1);
    });

    test('should watch upcoming reminders using default 48 hours window', () {
      // Arrange & Act
      final result = repository.watchUpcoming();

      // Assert
      expect(result, isA<Stream<List<Reminder>>>());
    });

    test('should watch upcoming reminders with custom time window', () {
      // Arrange
      const customHours = 24;

      // Act
      final result = repository.watchUpcoming(hours: customHours);

      // Assert
      expect(result, isA<Stream<List<Reminder>>>());
    });

    test('should propagate exception when reminder creation fails', () async {
      // Arrange
      const title = 'Failing Reminder';
      final whenUtc = DateTime.utc(2025, 12, 30, 12, 0);
      mockDao.insertException = Exception('Database error');

      // Act & Assert
      expect(
        () => repository.create(title: title, whenUtc: whenUtc),
        throwsException,
      );
      expect(mockNotifService.scheduleCallCount, 0);
    });
  });
}
