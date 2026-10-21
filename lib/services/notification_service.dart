import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/user_model.dart';
import 'database_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> init(String? uid) async {
    // 1. Request permissions (especially for Android 13+)
    await Permission.notification.request();

    // Initialize Timezone
    tz.initializeTimeZones();

    NotificationSettings fcmSettings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (fcmSettings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Get and save Token
      String? token = await _fcm.getToken();
      if (token != null && uid != null) {
        await DatabaseService(uid: uid).updateFcmToken(token);
      }

      // 3. Setup Local Notifications for Foreground
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      // Fix: using named parameter as required by the latest package version
      await _localNotifications.initialize(settings: initializationSettings);

      // 4. Register Background Handler (Static)
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 5. Listen for Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });
    }
  }

  // MUST be top-level or static for background handling
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    // Handle background message here if needed
  }

  // Show a popup when a notification arrives while the app is OPEN
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'class_connect_channel',
          'Class Notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    // Fix: using named parameters as required by the latest package version
    await _localNotifications.show(
      id: 0,
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? '',
      notificationDetails: platformChannelSpecifics,
    );
  }

  // Schedule Birthday Notifications for the class
  Future<void> scheduleBirthdayReminders(List<UserModel> users) async {
    // Clear previous schedules to avoid duplicates (optional but recommended)
    // await _localNotifications.cancelAll();
    // We might want to keep other notifications, so maybe just use a specific ID range for birthdays

    for (var user in users) {
      if (user.dateOfBirth != null) {
        await _scheduleNotificationForBirthday(user);
      }
    }
  }

  Future<void> _scheduleNotificationForBirthday(UserModel student) async {
    if (student.dateOfBirth == null) return;

    final now = DateTime.now();
    DateTime birthdayThisYear = DateTime(
      now.year,
      student.dateOfBirth!.month,
      student.dateOfBirth!.day,
    );

    if (birthdayThisYear.isBefore(now)) {
      birthdayThisYear = DateTime(
        now.year + 1,
        student.dateOfBirth!.month,
        student.dateOfBirth!.day,
      );
    }

    // Unique ID for each student based on hash or UID hash
    final int notifyId = student.uid.hashCode.abs();

    await _localNotifications.zonedSchedule(
      id: notifyId,
      title: '🎉 Birthday Alert!',
      body:
          'Today is ${student.name}\'s birthday! Don\'t forget to wish them! 🎂',
      scheduledDate: tz.TZDateTime.from(
        birthdayThisYear,
        tz.local,
      ).add(const Duration(hours: 9)), // 9 AM
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'birthday_reminders',
          'Birthday Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }
}
