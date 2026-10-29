import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Lectures extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get courseName => text().withLength(min: 1, max: 100)();
  TextColumn get courseCode => text().withDefault(const Constant(''))();
  TextColumn get room => text().withDefault(const Constant(''))();
  TextColumn get instructor => text().withDefault(const Constant(''))();
  IntColumn get dayOfWeek => integer()(); // 0: Sun, 1: Mon, ..., 6: Sat
  TextColumn get startTime => text()(); // "HH:mm" (24-hour)
  TextColumn get endTime => text()(); // "HH:mm" (24-hour)
  IntColumn get colorHex => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 150)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get priority =>
      integer().withDefault(const Constant(1))(); // 0: Low, 1: Med, 2: High
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get courseName => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Lectures, Tasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(lectures, lectures.createdAt);
        await m.addColumn(lectures, lectures.updatedAt);
      }
      if (from < 3) {
        await m.addColumn(tasks, tasks.createdAt);
        await m.addColumn(tasks, tasks.updatedAt);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'taskora_db');
  }
}
