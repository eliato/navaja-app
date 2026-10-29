import '../domain/models.dart';

class BookingSnapshot {
  const BookingSnapshot({
    required this.appointments,
    required this.waitlist,
    required this.upcomingAppointmentId,
  });

  final List<Appointment> appointments;
  final List<WaitlistEntry> waitlist;
  final String? upcomingAppointmentId;
}

abstract interface class BookingStore {
  Future<BookingSnapshot?> load();

  Future<void> save(BookingSnapshot snapshot);
}

class NoopBookingStore implements BookingStore {
  const NoopBookingStore();

  @override
  Future<BookingSnapshot?> load() async => null;

  @override
  Future<void> save(BookingSnapshot snapshot) async {}
}
