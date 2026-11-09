import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermissions();
  Future<bool> arePermissionsGranted();
  tz.Location get localLocation;
  Stream<String> get onNotificationTapped;
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
  });
  Future<void> cancel(int id);
  Future<void> cancelAll();
}

class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<String> _tappedController =
      StreamController<String>.broadcast();
  bool _isInitialized = false;
  late tz.Location _location;

  static const String lectureChannelId = 'taskora_lecture_reminders';
  static const String lectureChannelName = 'Lecture Reminders';
  static const String lectureChannelDesc =
      'Notifications for upcoming lectures and classes';

  static const String taskChannelId = 'taskora_task_deadlines';
  static const String taskChannelName = 'Task Deadlines';
  static const String taskChannelDesc =
      'Notifications for upcoming task and assignment deadlines';

  NotificationServiceImpl({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  tz.Location get localLocation => _location;

  @override
  Stream<String> get onNotificationTapped => _tappedController.stream;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Initialize timezone database and detect device location
    tz_data.initializeTimeZones();
    _location = _detectLocalLocation();

    // 2. Configure platform-specific initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Check if app was launched by tapping a notification
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      final payload = launchDetails.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!_tappedController.isClosed) {
            _tappedController.add(payload);
          }
        });
      }
    }

    // 3. Create Android notification channels
    if (!kIsWeb && Platform.isAndroid) {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            lectureChannelId,
            lectureChannelName,
            description: lectureChannelDesc,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            taskChannelId,
            taskChannelName,
            description: taskChannelDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
      }
    }

    _isInitialized = true;
  }

  tz.Location _detectLocalLocation() {
    try {
      final offset = DateTime.now().timeZoneOffset;
      final timeZoneName = DateTime.now().timeZoneName;

      if (tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
        return tz.getLocation(timeZoneName);
      }

      // Match based on UTC offset
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == offset) {
          return loc;
        }
      }
    } catch (_) {}

    return tz.local;
  }

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      if (!_tappedController.isClosed) {
        _tappedController.add(payload);
      }
    }
  }

  @override
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        final granted = await androidImplementation
            .requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (Platform.isIOS) {
      final iosImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return true;
  }

  @override
  Future<bool> arePermissionsGranted() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        final granted = await androidImplementation.areNotificationsEnabled();
        return granted ?? false;
      }
    }
    return true;
  }

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
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: importance,
      priority: priority,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      // First attempt exact schedule (preferred for 15-minute lecture reminders)
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    } catch (_) {
      // Graceful fallback to inexact scheduling if exact alarm permission is missing
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    }
  }

  @override
  Future<void> cancel(int id) async {
    if (!_isInitialized) {
      await initialize();
    }
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAll() async {
    if (!_isInitialized) {
      await initialize();
    }
    await _plugin.cancelAll();
  }
}
