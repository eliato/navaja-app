import 'package:flutter_test/flutter_test.dart';
import 'package:navaja/data/demo_catalog.dart';
import 'package:navaja/domain/models.dart';
import 'package:navaja/features/booking/booking_controller.dart';
import 'package:navaja/features/dashboard/dashboard_controller.dart';

void main() {
  test('computes seven days of revenue and applies barber filter', () {
    const catalog = DemoCatalog();
    final now = DateTime(2026, 10, 21, 12);
    final booking = BookingController(catalog, clock: () => now);
    final dashboard = DashboardController(booking, clock: () => now);
    final total = dashboard.weekTotalCents;

    dashboard.selectBarber('dani');

    expect(dashboard.weekRevenue, hasLength(7));
    expect(dashboard.weekTotalCents, lessThanOrEqualTo(total));
    expect(
      dashboard.agenda.every((appointment) => appointment.barber.id == 'dani'),
      isTrue,
    );
    dashboard.dispose();
    booking.dispose();
  });

  test('cancels an upcoming appointment and assigns its waitlist entry', () {
    const catalog = DemoCatalog();
    final now = DateTime(2026, 10, 21, 9);
    final booking = BookingController(catalog, clock: () => now);
    final appointment = Appointment(
      id: 'manual',
      clientName: 'Carlos',
      barber: catalog.barbers.first,
      service: catalog.services.first,
      start: DateTime(2026, 10, 21, 12),
      depositCents: 500,
    );
    booking.appointments.add(appointment);
    booking.waitlist
      ..clear()
      ..add(
        WaitlistEntry(
          clientName: 'Lucía',
          barber: catalog.barbers.first,
          start: appointment.start,
        ),
      );
    final dashboard = DashboardController(booking, clock: () => now);

    final notice = dashboard.cancel(appointment);

    expect(booking.appointments, isNot(contains(appointment)));
    expect(booking.waitlist, isEmpty);
    expect(notice.message, contains('Lucía'));
    dashboard.dispose();
    booking.dispose();
  });
}
