import 'package:flutter_test/flutter_test.dart';
import 'package:navaja/domain/reminder_time.dart';

void main() {
  test('schedules a reminder one day before when possible', () {
    final now = DateTime(2026, 10, 21, 9);
    final appointment = DateTime(2026, 10, 23, 12);

    expect(
      reminderTimeFor(appointmentStart: appointment, now: now),
      appointment.subtract(const Duration(days: 1)),
    );
  });

  test('falls back to one hour for an appointment on the same day', () {
    final now = DateTime(2026, 10, 21, 9);
    final appointment = DateTime(2026, 10, 21, 12);

    expect(
      reminderTimeFor(appointmentStart: appointment, now: now),
      appointment.subtract(const Duration(hours: 1)),
    );
  });

  test('falls back to fifteen minutes for a nearby appointment', () {
    final now = DateTime(2026, 10, 21, 11, 30);
    final appointment = DateTime(2026, 10, 21, 12);

    expect(
      reminderTimeFor(appointmentStart: appointment, now: now),
      appointment.subtract(const Duration(minutes: 15)),
    );
  });

  test('does not schedule after the appointment starts', () {
    final now = DateTime(2026, 10, 21, 12);

    expect(
      reminderTimeFor(appointmentStart: DateTime(2026, 10, 21, 12), now: now),
      isNull,
    );
  });
}
