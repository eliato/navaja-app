import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/demo_catalog.dart';
import '../../data/demo_schedule_seeder.dart';
import '../../domain/models.dart';
import '../../domain/slot_generator.dart';
import '../../services/appointment_integrations.dart';
import '../../services/booking_store.dart';
import '../../services/payment_gateway.dart';

enum BookingStep { barber, service, time }

enum BookingPhase { choosing, paying, confirmed, failed }

class BookingController extends ChangeNotifier {
  BookingController(
    this.catalog, {
    DateTime Function()? clock,
    this.slotGenerator = const SlotGenerator(),
    this.paymentGateway = const SimulatedPaymentGateway(),
    this.reminderService = const NoopAppointmentReminderService(),
    this.calendarService = const NoopAppointmentCalendarService(),
    this.store = const NoopBookingStore(),
  }) : _clock = clock ?? DateTime.now {
    appointments = DemoScheduleSeeder(catalog).appointments(_clock());
    final upcoming =
        appointments.where((item) => item.start.isAfter(_clock())).toList()
          ..sort((first, second) => first.start.compareTo(second.start));
    for (var index = 0; index < catalog.waitlistNames.length; index++) {
      if (index >= upcoming.length) break;
      waitlist.add(
        WaitlistEntry(
          clientName: catalog.waitlistNames[index],
          barber: upcoming[index].barber,
          start: upcoming[index].start,
        ),
      );
    }
    selectedDay = bookableDays.firstOrNull ?? _startOfDay(_clock());
  }

  final DemoCatalog catalog;
  final DateTime Function() _clock;
  final SlotGenerator slotGenerator;
  final PaymentGateway paymentGateway;
  final AppointmentReminderService reminderService;
  final AppointmentCalendarService calendarService;
  final BookingStore store;
  Future<void> _pendingSave = Future.value();
  late final List<Appointment> appointments;
  final List<WaitlistEntry> waitlist = [];

  BookingStep step = BookingStep.barber;
  Barber? selectedBarber;
  ShopService? selectedService;
  late DateTime selectedDay;
  TimeSlot? selectedSlot;
  WaitlistEntry? waitlistConfirmation;
  BookingPhase phase = BookingPhase.choosing;
  String clientName = '';
  String clientPhone = '';
  String? paymentError;
  Appointment? confirmedAppointment;
  Appointment? upcomingAppointment;

  List<DateTime> get bookableDays {
    final today = _startOfDay(_clock());
    return [
      for (var offset = 0; offset < 21; offset++)
        today.add(Duration(days: offset)),
    ].where(_hasTimeLeft).take(12).toList();
  }

  List<TimeSlot> get slots {
    final barber = selectedBarber;
    final service = selectedService;
    if (barber == null || service == null) return const [];
    return slotGenerator.slots(
      day: selectedDay,
      durationMinutes: service.durationMinutes,
      hours: catalog.shop.hours,
      booked: appointments
          .where(
            (appointment) =>
                appointment.barber.id == barber.id &&
                _sameDay(appointment.start, selectedDay),
          )
          .toList(),
      now: _clock(),
    );
  }

  bool get isReadyForCheckout =>
      selectedBarber != null && selectedService != null && selectedSlot != null;

  bool get hasClientName => clientName.trim().isNotEmpty;

  int get remainingCents =>
      (selectedService?.priceCents ?? 0) - catalog.shop.depositCents;

  void chooseBarber(Barber barber) {
    selectedBarber = barber;
    selectedService = null;
    selectedSlot = null;
    notifyListeners();
  }

  void chooseService(ShopService service) {
    selectedService = service;
    selectedSlot = null;
    notifyListeners();
  }

  void chooseDay(DateTime day) {
    if (_sameDay(day, selectedDay)) return;
    selectedDay = day;
    selectedSlot = null;
    notifyListeners();
  }

  void chooseSlot(TimeSlot slot) {
    if (!slot.isAvailable) return;
    selectedSlot = slot;
    notifyListeners();
  }

  void joinWaitlist(TimeSlot slot, String name) {
    final barber = selectedBarber;
    if (barber == null) return;
    final trimmed = name.trim();
    final entry = WaitlistEntry(
      clientName: trimmed.isEmpty ? 'Cliente' : trimmed,
      barber: barber,
      start: slot.start,
    );
    waitlist.add(entry);
    waitlistConfirmation = entry;
    _persist();
    notifyListeners();
  }

  void dismissWaitlistConfirmation() {
    if (waitlistConfirmation == null) return;
    waitlistConfirmation = null;
    notifyListeners();
  }

  Future<void> pay({required String name, required String phone}) async {
    if (phase == BookingPhase.paying) return;
    final barber = selectedBarber;
    final service = selectedService;
    final slot = selectedSlot;
    clientName = name.trim();
    clientPhone = phone.trim();
    if (clientName.isEmpty ||
        barber == null ||
        service == null ||
        slot == null) {
      return;
    }

    phase = BookingPhase.paying;
    paymentError = null;
    notifyListeners();
    try {
      await paymentGateway.chargeDeposit(
        amountCents: catalog.shop.depositCents,
        description: '${service.name} con ${barber.name}',
      );
      final clashes = appointments.any(
        (appointment) =>
            appointment.barber.id == barber.id &&
            appointment.overlaps(slot.start, service.durationMinutes),
      );
      if (clashes) {
        phase = BookingPhase.failed;
        paymentError = 'Alguien acaba de reservar esa hora. Elige otra.';
        notifyListeners();
        return;
      }
      final appointment = Appointment(
        id: 'booking-${_clock().microsecondsSinceEpoch}',
        clientName: clientName,
        barber: barber,
        service: service,
        start: slot.start,
        depositCents: catalog.shop.depositCents,
      );
      appointments.add(appointment);
      confirmedAppointment = appointment;
      upcomingAppointment = appointment;
      phase = BookingPhase.confirmed;
      _persist();
      notifyListeners();
    } catch (_) {
      phase = BookingPhase.failed;
      paymentError = 'No se ha podido completar el pago. Inténtalo otra vez.';
      notifyListeners();
    }
  }

  void clearFailure() {
    if (phase != BookingPhase.failed) return;
    phase = BookingPhase.choosing;
    paymentError = null;
    notifyListeners();
  }

  Future<bool> setReminder(Appointment appointment, {required bool enabled}) {
    if (enabled) return reminderService.schedule(appointment);
    return reminderService.cancel(appointment).then((_) => false);
  }

  Future<bool> addToCalendar(Appointment appointment) =>
      calendarService.add(appointment, catalog.shop);

  Future<void> restore() async {
    final snapshot = await store.load();
    if (snapshot == null) return;
    appointments
      ..clear()
      ..addAll(snapshot.appointments);
    waitlist
      ..clear()
      ..addAll(snapshot.waitlist);
    upcomingAppointment = snapshot.upcomingAppointmentId == null
        ? null
        : appointments
              .where(
                (appointment) =>
                    appointment.id == snapshot.upcomingAppointmentId &&
                    appointment.start.isAfter(_clock()),
              )
              .firstOrNull;
    notifyListeners();
  }

  Future<void> get persistenceSettled => _pendingSave;

  WaitlistEntry? cancelAppointment(Appointment appointment) {
    unawaited(reminderService.cancel(appointment));
    appointments.removeWhere((item) => item.id == appointment.id);
    if (upcomingAppointment?.id == appointment.id) upcomingAppointment = null;
    final waitingIndex = waitlist.indexWhere(
      (entry) =>
          entry.barber.id == appointment.barber.id &&
          !entry.start.isBefore(appointment.start) &&
          entry.start.isBefore(appointment.end),
    );
    final notified = waitingIndex < 0 ? null : waitlist.removeAt(waitingIndex);
    _persist();
    notifyListeners();
    return notified;
  }

  void goTo(BookingStep target) {
    if (step == target) return;
    step = target;
    notifyListeners();
  }

  void reset() {
    step = BookingStep.barber;
    selectedBarber = null;
    selectedService = null;
    selectedSlot = null;
    selectedDay = bookableDays.firstOrNull ?? _startOfDay(_clock());
    waitlistConfirmation = null;
    phase = BookingPhase.choosing;
    paymentError = null;
    confirmedAppointment = null;
    notifyListeners();
  }

  void _persist() {
    final snapshot = BookingSnapshot(
      appointments: List.unmodifiable(appointments),
      waitlist: List.unmodifiable(waitlist),
      upcomingAppointmentId: upcomingAppointment?.id,
    );
    _pendingSave = _pendingSave
        .then((_) => store.save(snapshot))
        .catchError((Object _) {});
  }

  bool _hasTimeLeft(DateTime day) {
    final blocks = catalog.shop.hours.blocksOn(day);
    if (blocks.isEmpty) return false;
    final closing = _startOfDay(day)
        .add(Duration(minutes: blocks.last.endMinute - 30));
    return closing.isAfter(_clock());
  }

  static DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
