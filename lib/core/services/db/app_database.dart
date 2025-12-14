import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get colorHex => text().withDefault(const Constant('#8E8E93'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  IntColumn get scheduledAt => integer()();
  TextColumn get timezone =>
      text().withDefault(const Constant('Asia/Makassar'))();
  BoolColumn get hasRecurrence =>
      boolean().withDefault(const Constant(false))();
  TextColumn get recurrenceRule => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get snoozedUntil => integer().nullable()();
  TextColumn get picturePath => text().nullable()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get priority => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class Notifications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get reminderId => integer().references(Reminders, #id)();
  IntColumn get fireTime => integer()();
  TextColumn get status => text().withDefault(const Constant('scheduled'))();
  TextColumn get channelId => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Categories, Reminders, Notifications])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();

      await into(
        categories,
      ).insert(CategoriesCompanion.insert(name: 'General'));
    },
    onUpgrade: (m, from, to) async {
      if (from == 1) {
        await customStatement(
          'ALTER TABLE categories ADD COLUMN is_pinned INTEGER DEFAULT 0 NOT NULL',
        );
      }
      if (from <= 2) {
        await customStatement(
          'ALTER TABLE categories ADD COLUMN is_archived INTEGER DEFAULT 0 NOT NULL',
        );
      }
    },
  );
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'cue_mind.db'));
    return NativeDatabase.createInBackground(file);
  });
}
