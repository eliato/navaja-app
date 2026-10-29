import 'dart:math';

import '../domain/models.dart';
import 'demo_catalog.dart';

class DemoScheduleSeeder {
  DemoScheduleSeeder(this.catalog, {this.stepMinutes = 30});

  final DemoCatalog catalog;
  final int stepMinutes;

  List<Appointment> appointments(DateTime now) {
    final random = Random(1987);
    final today = DateTime(now.year, now.month, now.day);
    final result = <Appointment>[];
    var id = 0;
    for (var offset = -14; offset <= 13; offset++) {
      final day = today.add(Duration(days: offset));
      final occupancy = switch (offset) {
        < 0 => 0.75,
        0 => 0.35,
        <= 2 => 0.30,
        _ => 0.20,
      };
      for (final barber in catalog.barbers) {
        for (final block in catalog.shop.hours.blocksOn(day)) {
          var minute = block.startMinute;
          while (minute + stepMinutes <= block.endMinute) {
            final service =
                catalog.services[random.nextInt(catalog.services.length)];
            final client =
                catalog.clientNames[random.nextInt(catalog.clientNames.length)];
            final fits = minute + service.durationMinutes <= block.endMinute;
            if (fits && random.nextDouble() < occupancy) {
              result.add(
                Appointment(
                  id: 'demo-${id++}',
                  clientName: client,
                  barber: barber,
                  service: service,
                  start: DateTime(
                    day.year,
                    day.month,
                    day.day,
                  ).add(Duration(minutes: minute)),
                  depositCents: catalog.shop.depositCents,
                ),
              );
              minute += _roundedUpToStep(service.durationMinutes);
            } else {
              minute += stepMinutes;
            }
          }
        }
      }
    }
    return result;
  }

  int _roundedUpToStep(int minutes) =>
      ((minutes + stepMinutes - 1) ~/ stepMinutes) * stepMinutes;
}
