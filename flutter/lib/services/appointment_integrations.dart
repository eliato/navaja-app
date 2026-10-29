import '../domain/models.dart';

abstract interface class AppointmentReminderService {
  Future<bool> schedule(Appointment appointment);

  Future<void> cancel(Appointment appointment);
}

abstract interface class AppointmentCalendarService {
  Future<bool> add(Appointment appointment, Shop shop);
}

class NoopAppointmentReminderService implements AppointmentReminderService {
  const NoopAppointmentReminderService();

  @override
  Future<bool> schedule(Appointment appointment) async => true;

  @override
  Future<void> cancel(Appointment appointment) async {}
}

class NoopAppointmentCalendarService implements AppointmentCalendarService {
  const NoopAppointmentCalendarService();

  @override
  Future<bool> add(Appointment appointment, Shop shop) async => false;
}
