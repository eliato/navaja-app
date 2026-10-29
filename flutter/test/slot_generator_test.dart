import 'package:flutter_test/flutter_test.dart';
import 'package:navaja/domain/models.dart';
import 'package:navaja/domain/slot_generator.dart';

void main() {
  const generator = SlotGenerator();
  const hours = OpeningHours(
    weekdays: [OpeningBlock(startMinute: 600, endMinute: 720)],
    saturday: [],
  );
  const barber = Barber(id: 'dani', name: 'Dani', specialty: 'Degradados');
  const haircut = ShopService(
    id: 'corte',
    name: 'Corte',
    durationMinutes: 30,
    priceCents: 1500,
  );
  final day = DateTime(2026, 10, 16);
  final dayBefore = DateTime(2026, 10, 15);

  test('offers every start time that fits before closing', () {
    final slots = generator.slots(
      day: day,
      durationMinutes: 30,
      hours: hours,
      booked: const [],
      now: dayBefore,
    );

    expect(slots.map((slot) => slot.start), [
      DateTime(2026, 10, 16, 10),
      DateTime(2026, 10, 16, 10, 30),
      DateTime(2026, 10, 16, 11),
      DateTime(2026, 10, 16, 11, 30),
    ]);
  });

  test('does not offer a service that runs past closing', () {
    final slots = generator.slots(
      day: day,
      durationMinutes: 45,
      hours: hours,
      booked: const [],
      now: dayBefore,
    );

    expect(slots.last.start, DateTime(2026, 10, 16, 11));
  });

  test('marks overlapping appointments as taken', () {
    final booking = Appointment(
      id: 'booking',
      clientName: 'Hugo',
      barber: barber,
      service: haircut,
      start: DateTime(2026, 10, 16, 10, 30),
      depositCents: 500,
    );
    final slots = generator.slots(
      day: day,
      durationMinutes: 30,
      hours: hours,
      booked: [booking],
      now: dayBefore,
    );

    expect(
      slots
          .firstWhere(
            (slot) => slot.start.hour == 10 && slot.start.minute == 30,
          )
          .isAvailable,
      isFalse,
    );
  });

  test('hides start times that have already passed', () {
    final slots = generator.slots(
      day: day,
      durationMinutes: 30,
      hours: hours,
      booked: const [],
      now: DateTime(2026, 10, 16, 11, 10),
    );

    expect(slots.map((slot) => slot.start), [DateTime(2026, 10, 16, 11, 30)]);
  });

  test('offers nothing on Sunday', () {
    final slots = generator.slots(
      day: DateTime(2026, 10, 18),
      durationMinutes: 30,
      hours: hours,
      booked: const [],
      now: dayBefore,
    );

    expect(slots, isEmpty);
  });
}
