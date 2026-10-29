import 'package:flutter_test/flutter_test.dart';
import 'package:navaja/data/demo_catalog.dart';
import 'package:navaja/domain/models.dart';
import 'package:navaja/features/booking/booking_controller.dart';
import 'package:navaja/services/appointment_integrations.dart';
import 'package:navaja/services/booking_store.dart';
import 'package:navaja/services/payment_gateway.dart';

void main() {
  test('booking controller keeps choices while advancing', () {
    const catalog = DemoCatalog();
    final controller = BookingController(catalog);

    controller.chooseBarber(catalog.barbers.first);
    controller.goTo(BookingStep.service);
    controller.chooseService(catalog.services.first);
    controller.goTo(BookingStep.time);

    expect(controller.selectedBarber?.id, 'dani');
    expect(controller.selectedService?.id, 'corte');
    expect(controller.step, BookingStep.time);
  });

  test('changing barber clears the selected service', () {
    const catalog = DemoCatalog();
    final controller = BookingController(catalog)
      ..chooseBarber(catalog.barbers.first)
      ..chooseService(catalog.services.first)
      ..chooseBarber(catalog.barbers.last);

    expect(controller.selectedBarber?.id, 'ruben');
    expect(controller.selectedService, isNull);
  });

  test('selecting a day clears the selected slot', () {
    const catalog = DemoCatalog();
    final now = DateTime(2026, 10, 21, 9);
    final controller = BookingController(catalog, clock: () => now)
      ..chooseBarber(catalog.barbers.first)
      ..chooseService(catalog.services.first);
    final available = controller.slots.firstWhere((slot) => slot.isAvailable);
    controller.chooseSlot(available);
    expect(controller.isReadyForCheckout, isTrue);

    controller.chooseDay(controller.bookableDays[1]);

    expect(controller.selectedSlot, isNull);
    expect(controller.isReadyForCheckout, isFalse);
  });

  test('joins the waitlist for a taken slot', () {
    const catalog = DemoCatalog();
    final controller = BookingController(
      catalog,
      clock: () => DateTime(2026, 10, 21, 9),
    )..chooseBarber(catalog.barbers.first);
    final slot = TimeSlot(
      start: DateTime(2026, 10, 22, 10),
      isAvailable: false,
    );

    controller.joinWaitlist(slot, '  Lucía  ');

    expect(controller.waitlist.last.clientName, 'Lucía');
    expect(controller.waitlistConfirmation?.start, slot.start);
  });

  test('payment creates and exposes the confirmed appointment', () async {
    const catalog = DemoCatalog();
    final now = DateTime(2026, 10, 21, 9);
    final store = _MemoryBookingStore();
    final controller =
        BookingController(
            catalog,
            clock: () => now,
            paymentGateway: const _ImmediatePaymentGateway(),
            store: store,
          )
          ..chooseBarber(catalog.barbers.first)
          ..chooseService(catalog.services.first);
    controller.chooseSlot(
      controller.slots.firstWhere((slot) => slot.isAvailable),
    );

    await controller.pay(name: ' Carlos ', phone: '600 000 000');

    expect(controller.phase, BookingPhase.confirmed);
    expect(controller.confirmedAppointment?.clientName, 'Carlos');
    expect(controller.upcomingAppointment, controller.confirmedAppointment);
    expect(controller.appointments, contains(controller.confirmedAppointment));
    await controller.persistenceSettled;
    expect(
      store.saved.last.upcomingAppointmentId,
      controller.confirmedAppointment?.id,
    );
  });

  test(
    'restores appointments, waitlist and a future upcoming booking',
    () async {
      const catalog = DemoCatalog();
      final now = DateTime(2026, 10, 21, 9);
      final appointment = Appointment(
        id: 'persisted',
        clientName: 'Carlos',
        barber: catalog.barbers.first,
        service: catalog.services.first,
        start: DateTime(2026, 10, 23, 12),
        depositCents: 500,
      );
      final waiting = WaitlistEntry(
        clientName: 'Lucía',
        barber: catalog.barbers.first,
        start: appointment.start,
      );
      final store = _MemoryBookingStore(
        initial: BookingSnapshot(
          appointments: [appointment],
          waitlist: [waiting],
          upcomingAppointmentId: appointment.id,
        ),
      );
      final controller = BookingController(
        catalog,
        clock: () => now,
        store: store,
      );

      await controller.restore();

      expect(controller.appointments, [appointment]);
      expect(controller.waitlist, [waiting]);
      expect(controller.upcomingAppointment, appointment);
    },
  );

  test('does not restore a past appointment as upcoming', () async {
    const catalog = DemoCatalog();
    final appointment = Appointment(
      id: 'past',
      clientName: 'Carlos',
      barber: catalog.barbers.first,
      service: catalog.services.first,
      start: DateTime(2026, 10, 20, 12),
      depositCents: 500,
    );
    final controller = BookingController(
      catalog,
      clock: () => DateTime(2026, 10, 21, 9),
      store: _MemoryBookingStore(
        initial: BookingSnapshot(
          appointments: [appointment],
          waitlist: const [],
          upcomingAppointmentId: appointment.id,
        ),
      ),
    );

    await controller.restore();

    expect(controller.upcomingAppointment, isNull);
  });

  test('delegates reminder and calendar actions to device services', () async {
    const catalog = DemoCatalog();
    final reminders = _RecordingReminderService();
    final calendar = _RecordingCalendarService();
    final controller = BookingController(
      catalog,
      clock: () => DateTime(2026, 10, 21, 9),
      reminderService: reminders,
      calendarService: calendar,
    );
    final appointment = controller.appointments.first;

    expect(await controller.setReminder(appointment, enabled: true), isTrue);
    expect(await controller.addToCalendar(appointment), isTrue);
    await controller.setReminder(appointment, enabled: false);
    controller.cancelAppointment(appointment);

    expect(reminders.scheduled, [appointment]);
    expect(reminders.cancelled, [appointment, appointment]);
    expect(calendar.added, [appointment]);
  });
}

class _ImmediatePaymentGateway implements PaymentGateway {
  const _ImmediatePaymentGateway();

  @override
  Future<PaymentReceipt> chargeDeposit({
    required int amountCents,
    required String description,
  }) async => PaymentReceipt(reference: 'pi_test', amountCents: amountCents);
}

class _RecordingReminderService implements AppointmentReminderService {
  final List<Appointment> scheduled = [];
  final List<Appointment> cancelled = [];

  @override
  Future<bool> schedule(Appointment appointment) async {
    scheduled.add(appointment);
    return true;
  }

  @override
  Future<void> cancel(Appointment appointment) async {
    cancelled.add(appointment);
  }
}

class _RecordingCalendarService implements AppointmentCalendarService {
  final List<Appointment> added = [];

  @override
  Future<bool> add(Appointment appointment, Shop shop) async {
    added.add(appointment);
    return true;
  }
}

class _MemoryBookingStore implements BookingStore {
  _MemoryBookingStore({this.initial});

  final BookingSnapshot? initial;
  final List<BookingSnapshot> saved = [];

  @override
  Future<BookingSnapshot?> load() async => initial;

  @override
  Future<void> save(BookingSnapshot snapshot) async {
    saved.add(snapshot);
  }
}
