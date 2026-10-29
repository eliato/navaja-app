import 'package:flutter/foundation.dart';

import '../../data/demo_catalog.dart';
import '../../domain/models.dart';
import '../booking/booking_controller.dart';

class DailyRevenue {
  const DailyRevenue({required this.day, required this.cents});

  final DateTime day;
  final int cents;
}

enum AgendaStatus { past, inProgress, upcoming }

class DashboardNotice {
  const DashboardNotice({required this.title, required this.message});

  final String title;
  final String message;
}

class DashboardController extends ChangeNotifier {
  DashboardController(this.booking, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    booking.addListener(_bookingChanged);
  }

  final BookingController booking;
  final DateTime Function() _clock;
  String? barberFilterId;

  DemoCatalog get catalog => booking.catalog;
  DateTime get now => _clock();
  DateTime get today {
    final current = now;
    return DateTime(current.year, current.month, current.day);
  }

  bool get isOpenToday => catalog.shop.hours.blocksOn(today).isNotEmpty;

  List<Appointment> get agenda {
    final items = booking.appointments
        .where(
          (appointment) =>
              _sameDay(appointment.start, today) &&
              (barberFilterId == null ||
                  appointment.barber.id == barberFilterId),
        )
        .toList();
    items.sort((first, second) => first.start.compareTo(second.start));
    return items;
  }

  List<DailyRevenue> get weekRevenue => [
    for (var offset = 6; offset >= 0; offset--)
      _dailyRevenue(today.subtract(Duration(days: offset)), now),
  ];

  int get weekTotalCents =>
      weekRevenue.fold(0, (total, item) => total + item.cents);

  int? get weekChangePercent {
    final previousCutoff = now.subtract(const Duration(days: 7));
    var previous = 0;
    for (var offset = 7; offset < 14; offset++) {
      previous += _dailyRevenue(
        today.subtract(Duration(days: offset)),
        previousCutoff,
      ).cents;
    }
    if (previous == 0) return null;
    return ((weekTotalCents - previous) / previous * 100).round();
  }

  int get waitlistCount => booking.waitlist
      .where(
        (entry) =>
            entry.start.isAfter(now) &&
            (barberFilterId == null || entry.barber.id == barberFilterId),
      )
      .length;

  void selectBarber(String? barberId) {
    if (barberFilterId == barberId) return;
    barberFilterId = barberId;
    notifyListeners();
  }

  AgendaStatus statusOf(Appointment appointment) {
    if (!appointment.end.isAfter(now)) return AgendaStatus.past;
    if (!appointment.start.isAfter(now)) return AgendaStatus.inProgress;
    return AgendaStatus.upcoming;
  }

  DashboardNotice cancel(Appointment appointment) {
    final notified = booking.cancelAppointment(appointment);
    final time = _clockTime(appointment.start);
    if (notified != null) {
      return DashboardNotice(
        title: 'Se ha liberado las $time',
        message:
            'Hemos avisado a ${notified.clientName}, de la lista de espera',
      );
    }
    return DashboardNotice(
      title: 'Cita cancelada',
      message: 'El hueco de las $time vuelve a estar libre',
    );
  }

  DailyRevenue _dailyRevenue(DateTime day, DateTime cutoff) {
    final cents = booking.appointments
        .where(
          (appointment) =>
              _sameDay(appointment.start, day) &&
              (barberFilterId == null ||
                  appointment.barber.id == barberFilterId) &&
              !appointment.start.isAfter(cutoff),
        )
        .fold(
          0,
          (total, appointment) => total + appointment.service.priceCents,
        );
    return DailyRevenue(day: day, cents: cents);
  }

  void _bookingChanged() => notifyListeners();

  static bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  static String _clockTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    booking.removeListener(_bookingChanged);
    super.dispose();
  }
}
