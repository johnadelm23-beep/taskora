import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskora/app/app.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/core/di/injection_container.dart';
import 'package:taskora/features/home/presentation/screens/home_screen.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';
import 'package:taskora/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:taskora/features/schedule/presentation/screens/schedule_screen.dart';
import 'package:taskora/features/schedule/presentation/widgets/lecture_card.dart';
import 'package:taskora/features/settings/presentation/screens/settings_screen.dart';
import 'package:taskora/features/tasks/domain/entities/task_entity.dart';
import 'package:taskora/features/tasks/presentation/cubit/task_cubit.dart';
import 'package:taskora/features/tasks/presentation/cubit/task_state.dart';
import 'package:taskora/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:taskora/features/tasks/presentation/widgets/task_card.dart';

void main() {
  late AppDatabase testDb;

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    testDb = AppDatabase(NativeDatabase.memory());
    await initDependencies(customDatabase: testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  test('LectureEntity correctly detects overlapping times on the same day', () {
    const lectureA = LectureEntity(
      id: 1,
      courseName: 'Physics',
      dayOfWeek: 1,
      startTime: '09:00',
      endTime: '10:30',
    );

    const overlappingLecture = LectureEntity(
      id: 2,
      courseName: 'Chemistry',
      dayOfWeek: 1,
      startTime: '10:00',
      endTime: '11:30',
    );

    const nonOverlappingLecture = LectureEntity(
      id: 3,
      courseName: 'Math',
      dayOfWeek: 1,
      startTime: '10:30',
      endTime: '12:00',
    );

    const differentDayLecture = LectureEntity(
      id: 4,
      courseName: 'Biology',
      dayOfWeek: 2,
      startTime: '09:00',
      endTime: '10:30',
    );

    expect(lectureA.overlapsWith(overlappingLecture), isTrue);
    expect(lectureA.overlapsWith(nonOverlappingLecture), isFalse);
    expect(lectureA.overlapsWith(differentDayLecture), isFalse);
    expect(
      lectureA.overlapsWith(lectureA),
      isFalse,
    ); // Same ID should not conflict with itself
  });

  testWidgets('Taskora renders Home and navigates through all 4 tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TaskoraApp());
    await tester.pumpAndSettle();

    // Verify Home is initially active
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Tap Schedule destination
    await tester.tap(find.byIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(ScheduleScreen), findsOneWidget);

    // Tap Tasks destination
    await tester.tap(find.byIcon(Icons.checklist_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(TasksScreen), findsOneWidget);

    // Tap Settings destination
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    // Clean unmount
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'Adding, updating, and deleting a lecture via ScheduleCubit updates UI',
    (WidgetTester tester) async {
      await tester.pumpWidget(const TaskoraApp());
      await tester.pumpAndSettle();

      // Switch to Schedule tab
      await tester.tap(find.byIcon(Icons.calendar_month_outlined));
      await tester.pumpAndSettle();

      final scheduleCubit = tester
          .element(find.byType(ScheduleScreen))
          .read<ScheduleCubit>();

      // 1. Add lecture
      const lecture = LectureEntity(
        id: 0,
        courseName: 'Mobile Development',
        courseCode: 'CS302',
        room: 'Hall 4',
        instructor: 'Dr. John',
        dayOfWeek: 1, // Monday
        startTime: '10:00',
        endTime: '11:30',
      );

      final addSuccess = await scheduleCubit.addLecture(lecture);
      expect(addSuccess, isTrue);

      // Switch to day 1 to see the lecture
      scheduleCubit.selectDay(1);
      await tester.pumpAndSettle();

      expect(find.byType(LectureCard), findsWidgets);
      expect(find.text('Mobile Development'), findsWidgets);

      // 2. Prevent overlapping lecture
      const overlapping = LectureEntity(
        id: 0,
        courseName: 'Database Systems',
        dayOfWeek: 1,
        startTime: '10:30',
        endTime: '12:00',
      );
      final conflictSuccess = await scheduleCubit.addLecture(overlapping);
      expect(conflictSuccess, isFalse);
      expect(scheduleCubit.state.errorMessage, contains('Time conflict'));

      // 3. Delete lecture
      final createdLecture = scheduleCubit.state.dayLectures.first;
      await scheduleCubit.deleteLecture(createdLecture.id);
      await tester.pumpAndSettle();

      expect(find.text('Mobile Development'), findsNothing);

      // Clean unmount
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Creating, completing, filtering, and deleting a task via TaskCubit updates UI',
    (WidgetTester tester) async {
      await tester.pumpWidget(const TaskoraApp());
      await tester.pumpAndSettle();

      // Switch to Tasks tab
      await tester.tap(find.byIcon(Icons.checklist_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(TasksScreen), findsOneWidget);

      final taskCubit = tester
          .element(find.byType(TasksScreen))
          .read<TaskCubit>();

      // 1. Create a task
      final created = await taskCubit.createTask(
        title: 'Algorithms Homework 3',
        courseName: 'CS301',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        priority: TaskPriority.high,
      );
      expect(created, isTrue);
      await tester.pumpAndSettle();

      expect(find.byType(TaskCard), findsOneWidget);
      expect(find.text('Algorithms Homework 3'), findsOneWidget);
      expect(find.text('CS301'), findsOneWidget);

      // 2. Complete task
      final taskId = taskCubit.state.allTasks.first.id;
      await taskCubit.toggleTaskCompletion(taskId, true);
      await tester.pumpAndSettle();

      // 3. Test filter
      taskCubit.setFilter(TaskFilter.pending);
      await tester.pumpAndSettle();
      expect(find.byType(TaskCard), findsNothing);

      taskCubit.setFilter(TaskFilter.completed);
      await tester.pumpAndSettle();
      expect(find.byType(TaskCard), findsOneWidget);

      // 4. Delete task
      await taskCubit.deleteTask(taskId);
      await tester.pumpAndSettle();
      expect(find.byType(TaskCard), findsNothing);

      // 5. Navigate to Home
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      // Clean unmount
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
