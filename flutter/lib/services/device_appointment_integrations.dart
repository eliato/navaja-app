import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/models.dart';
import '../domain/reminder_time.dart';
import 'appointment_integrations.dart';

class LocalNotificationReminderService implements AppointmentReminderService {
  LocalNotificationReminderService({
    FlutterLocalNotificationsPlugin? notifications,
    this.timeZoneName = 'Europe/Madrid',
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _notifications;
  final String timeZoneName;
  Future<void>? _initialization;

  @override
  Future<bool> schedule(Appointment appointment) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return false;
    }

    try {
      final reminder = reminderTimeFor(
        appointmentStart: appointment.start,
        now: DateTime.now(),
      );
      if (reminder == null) return false;
      await (_initialization ??= _initialize());
      if (!await _requestPermission()) return false;

      final location = tz.getLocation(timeZoneName);
      final scheduledDate = tz.TZDateTime(
        location,
        reminder.year,
        reminder.month,
        reminder.day,
        reminder.hour,
        reminder.minute,
      );
      if (!scheduledDate.isAfter(tz.TZDateTime.now(location))) return false;

      await _notifications.zonedSchedule(
        id: _notificationId(appointment.id),
        title: appointment.start.difference(reminder).inHours >= 23
            ? 'Tu cita en Navaja es mañana'
            : 'Tu cita en Navaja es pronto',
        body:
            '${appointment.service.name} con ${appointment.barber.name} a las '
            '${appointment.start.hour.toString().padLeft(2, '0')}:'
            '${appointment.start.minute.toString().padLeft(2, '0')}',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'appointment_reminders',
            'Recordatorios de citas',
            channelDescription: 'Avisos de las próximas citas en Navaja',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: appointment.id,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> cancel(Appointment appointment) async {
    try {
      await (_initialization ??= _initialize());
      await _notifications.cancel(id: _notificationId(appointment.id));
    } catch (_) {
      // Cancellation is best-effort when platform services are unavailable.
    }
  }

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  Future<bool> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          true;
    }
    return await _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  int _notificationId(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}

class DeviceCalendarService implements AppointmentCalendarService {
  const DeviceCalendarService();

  @override
  Future<bool> add(Appointment appointment, Shop shop) async {
    if (kIsWeb) return false;
    try {
      return await Add2Calendar.addEvent2Cal(
        Event(
          title: '${appointment.service.name} en ${shop.name}',
          description: 'Cita con ${appointment.barber.name}',
          location: shop.address,
          startDate: appointment.start,
          endDate: appointment.end,
          iosParams: const IOSParams(reminder: Duration(days: 1)),
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
