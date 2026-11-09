import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:taskora/app/app.dart';
import 'package:taskora/core/di/injection_container.dart';
import 'package:taskora/core/notification/notification_service.dart';
import 'package:taskora/features/reminders/domain/services/reminder_scheduler.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await initDependencies();

  // Initialize notifications and sync active reminders
  try {
    final notificationService = sl<NotificationService>();
    await notificationService.initialize();
    final reminderScheduler = sl<ReminderScheduler>();
    unawaited(reminderScheduler.resyncAllReminders());
  } catch (_) {
    // Graceful startup safety
  }

  FlutterNativeSplash.remove();
  runApp(const TaskoraApp());
}
