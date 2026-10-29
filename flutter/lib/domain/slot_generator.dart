import 'models.dart';

class SlotGenerator {
  const SlotGenerator({this.stepMinutes = 30});

  final int stepMinutes;

  List<TimeSlot> slots({
    required DateTime day,
    required int durationMinutes,
    required OpeningHours hours,
    required List<Appointment> booked,
    required DateTime now,
  }) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final result = <TimeSlot>[];
    for (final block in hours.blocksOn(day)) {
      for (
        var minute = block.startMinute;
        minute <= block.endMinute - durationMinutes;
        minute += stepMinutes
      ) {
        final start = dayStart.add(Duration(minutes: minute));
        if (!start.isAfter(now)) continue;
        final taken = booked.any(
          (appointment) => appointment.overlaps(start, durationMinutes),
        );
        result.add(TimeSlot(start: start, isAvailable: !taken));
      }
    }
    return result;
  }
}
