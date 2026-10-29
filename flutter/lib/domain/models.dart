class Barber {
  const Barber({required this.id, required this.name, required this.specialty});

  final String id;
  final String name;
  final String specialty;

  String get initial => name.substring(0, 1);
}

class ShopService {
  const ShopService({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.priceCents,
  });

  final String id;
  final String name;
  final int durationMinutes;
  final int priceCents;
}

class OpeningBlock {
  const OpeningBlock({required this.startMinute, required this.endMinute});

  final int startMinute;
  final int endMinute;
}

class OpeningHours {
  const OpeningHours({required this.weekdays, required this.saturday});

  final List<OpeningBlock> weekdays;
  final List<OpeningBlock> saturday;

  List<OpeningBlock> blocksOn(DateTime day) {
    if (day.weekday == DateTime.sunday) return const [];
    if (day.weekday == DateTime.saturday) return saturday;
    return weekdays;
  }
}

class Shop {
  const Shop({
    required this.name,
    required this.address,
    required this.depositCents,
    required this.hours,
  });

  final String name;
  final String address;
  final int depositCents;
  final OpeningHours hours;
}

class Appointment {
  const Appointment({
    required this.id,
    required this.clientName,
    required this.barber,
    required this.service,
    required this.start,
    required this.depositCents,
  });

  final String id;
  final String clientName;
  final Barber barber;
  final ShopService service;
  final DateTime start;
  final int depositCents;

  DateTime get end => start.add(Duration(minutes: service.durationMinutes));

  bool overlaps(DateTime otherStart, int durationMinutes) {
    final otherEnd = otherStart.add(Duration(minutes: durationMinutes));
    return start.isBefore(otherEnd) && otherStart.isBefore(end);
  }
}

class TimeSlot {
  const TimeSlot({required this.start, required this.isAvailable});

  final DateTime start;
  final bool isAvailable;
}

class WaitlistEntry {
  const WaitlistEntry({
    required this.clientName,
    required this.barber,
    required this.start,
  });

  final String clientName;
  final Barber barber;
  final DateTime start;
}
