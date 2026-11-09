import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskora/app/app.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/core/di/injection_container.dart';
import 'package:taskora/core/notification/notification_service.dart';
import 'package:taskora/features/home/presentation/screens/home_screen.dart';
import 'package:taskora/features/schedule/presentation/screens/schedule_screen.dart';
import 'package:taskora/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class FakeInteractiveNotificationService implements NotificationService {
  final StreamController<String> _tapController =
      StreamController<String>.broadcast();
  late tz.Location _location;

  FakeInteractiveNotificationService() {
    tz_data.initializeTimeZones();
    _location = tz.UTC;
  }

  @override
  tz.Location get localLocation => _location;

  @override
  Stream<String> get onNotificationTapped => _tapController.stream;

  void triggerTap(String payload) {
    _tapController.add(payload);
  }

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> arePermissionsGranted() async => true;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> scheduleZoned({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
    String channelId = 'taskora_reminders',
    String channelName = 'Taskora Reminders',
    String channelDescription = 'General reminders from Taskora',
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) async {}

  void dispose() {
    _tapController.close();
  }
}

void main() {
  late AppDatabase testDb;
  late FakeInteractiveNotificationService fakeNotificationService;

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    testDb = AppDatabase(NativeDatabase.memory());
    fakeNotificationService = FakeInteractiveNotificationService();

    await initDependencies(
      customDatabase: testDb,
      customNotificationService: fakeNotificationService,
    );
  });

  tearDown(() async {
    fakeNotificationService.dispose();
    await testDb.close();
  });

  testWidgets(
    'tapping notification navigates directly to Schedule (tab 1) or Tasks (tab 2)',
    (WidgetTester tester) async {
      await tester.pumpWidget(const TaskoraApp());
      await tester.pumpAndSettle();

      // Initial tab is Home (0)
      expect(find.byType(HomeScreen), findsOneWidget);

      // Simulate tapping a lecture notification with payload 'schedule:42'
      fakeNotificationService.triggerTap('schedule:42');
      await tester.pumpAndSettle();

      // Navigation should transition to Schedule screen
      expect(find.byType(ScheduleScreen), findsOneWidget);

      // Simulate tapping a task notification with payload 'tasks:10'
      fakeNotificationService.triggerTap('tasks:10');
      await tester.pumpAndSettle();

      // Navigation should transition to Tasks screen
      expect(find.byType(TasksScreen), findsOneWidget);

      // Clean unmount
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
