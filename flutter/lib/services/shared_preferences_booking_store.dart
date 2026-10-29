import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/demo_catalog.dart';
import '../domain/models.dart';
import 'booking_store.dart';

class SharedPreferencesBookingStore implements BookingStore {
  SharedPreferencesBookingStore(this.catalog) : _preferences = null;

  SharedPreferencesBookingStore.withPreferences(
    this.catalog,
    this._preferences,
  );

  static const _key = 'booking_state_v1';
  static const _version = 1;

  final DemoCatalog catalog;
  SharedPreferencesAsync? _preferences;

  SharedPreferencesAsync get _client =>
      _preferences ??= SharedPreferencesAsync();

  @override
  Future<BookingSnapshot?> load() async {
    try {
      final encoded = await _client.getString(_key);
      if (encoded == null) return null;
      final json = jsonDecode(encoded);
      if (json is! Map<String, dynamic> || json['version'] != _version) {
        return null;
      }

      final appointments = <Appointment>[];
      for (final value in json['appointments'] as List<dynamic>? ?? const []) {
        final appointment = _appointmentFromJson(value);
        if (appointment != null) appointments.add(appointment);
      }
      final waitlist = <WaitlistEntry>[];
      for (final value in json['waitlist'] as List<dynamic>? ?? const []) {
        final entry = _waitlistEntryFromJson(value);
        if (entry != null) waitlist.add(entry);
      }
      return BookingSnapshot(
        appointments: appointments,
        waitlist: waitlist,
        upcomingAppointmentId: json['upcomingAppointmentId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(BookingSnapshot snapshot) async {
    final json = <String, Object?>{
      'version': _version,
      'appointments': snapshot.appointments.map(_appointmentToJson).toList(),
      'waitlist': snapshot.waitlist.map(_waitlistEntryToJson).toList(),
      'upcomingAppointmentId': snapshot.upcomingAppointmentId,
    };
    await _client.setString(_key, jsonEncode(json));
  }

  Map<String, Object> _appointmentToJson(Appointment appointment) => {
    'id': appointment.id,
    'clientName': appointment.clientName,
    'barberId': appointment.barber.id,
    'serviceId': appointment.service.id,
    'start': appointment.start.toIso8601String(),
    'depositCents': appointment.depositCents,
  };

  Appointment? _appointmentFromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final barber = _barber(value['barberId']);
    final service = _service(value['serviceId']);
    final start = DateTime.tryParse(value['start'] as String? ?? '');
    final id = value['id'];
    final clientName = value['clientName'];
    final depositCents = value['depositCents'];
    if (barber == null ||
        service == null ||
        start == null ||
        id is! String ||
        clientName is! String ||
        depositCents is! int) {
      return null;
    }
    return Appointment(
      id: id,
      clientName: clientName,
      barber: barber,
      service: service,
      start: start,
      depositCents: depositCents,
    );
  }

  Map<String, Object> _waitlistEntryToJson(WaitlistEntry entry) => {
    'clientName': entry.clientName,
    'barberId': entry.barber.id,
    'start': entry.start.toIso8601String(),
  };

  WaitlistEntry? _waitlistEntryFromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final barber = _barber(value['barberId']);
    final start = DateTime.tryParse(value['start'] as String? ?? '');
    final clientName = value['clientName'];
    if (barber == null || start == null || clientName is! String) return null;
    return WaitlistEntry(clientName: clientName, barber: barber, start: start);
  }

  Barber? _barber(Object? id) =>
      catalog.barbers.where((barber) => barber.id == id).firstOrNull;

  ShopService? _service(Object? id) =>
      catalog.services.where((service) => service.id == id).firstOrNull;
}
