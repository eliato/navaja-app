import 'models.dart';

String euros(int cents) {
  final amount = cents / 100;
  final decimals = cents % 100 == 0 ? 0 : 2;
  return '${amount.toStringAsFixed(decimals).replaceAll('.', ',')} €';
}

String clockTimeFromMinutes(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

String clockTime(DateTime date) =>
    clockTimeFromMinutes(date.hour * 60 + date.minute);

String weekdayShort(DateTime date) => const {
  DateTime.monday: 'lun',
  DateTime.tuesday: 'mar',
  DateTime.wednesday: 'mié',
  DateTime.thursday: 'jue',
  DateTime.friday: 'vie',
  DateTime.saturday: 'sáb',
  DateTime.sunday: 'dom',
}[date.weekday]!;

String weekdayLong(DateTime date) => const {
  DateTime.monday: 'lunes',
  DateTime.tuesday: 'martes',
  DateTime.wednesday: 'miércoles',
  DateTime.thursday: 'jueves',
  DateTime.friday: 'viernes',
  DateTime.saturday: 'sábado',
  DateTime.sunday: 'domingo',
}[date.weekday]!;

String monthShort(DateTime date) => const [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
][date.month - 1];

String monthLong(DateTime date) => const [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
][date.month - 1];

String longDate(DateTime date) =>
    '${_capitalized(weekdayLong(date))}, ${date.day} de ${monthLong(date)}';

String shortDate(DateTime date) =>
    '${_capitalized(weekdayShort(date))} ${date.day} ${monthShort(date)}';

String relativeTimePhrase(DateTime date, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final days = target.difference(today).inDays;
  if (days == 0) return 'hoy a las ${clockTime(date)}';
  if (days == 1) return 'mañana a las ${clockTime(date)}';
  return 'el ${weekdayLong(date)} a las ${clockTime(date)}';
}

String _capitalized(String value) =>
    '${value.substring(0, 1).toUpperCase()}${value.substring(1)}';

String hoursText(List<OpeningBlock> blocks) => blocks
    .map(
      (block) =>
          '${clockTimeFromMinutes(block.startMinute)}–${clockTimeFromMinutes(block.endMinute)}',
    )
    .join('  ·  ');

class ShopStatus {
  const ShopStatus({required this.isOpen, required this.message});

  final bool isOpen;
  final String message;
}

ShopStatus shopStatus(OpeningHours hours, DateTime now) {
  final minute = now.hour * 60 + now.minute;
  for (final block in hours.blocksOn(now)) {
    if (minute < block.startMinute) {
      return ShopStatus(
        isOpen: false,
        message:
            'Cerrado · abre hoy a las ${clockTimeFromMinutes(block.startMinute)}',
      );
    }
    if (minute < block.endMinute) {
      return ShopStatus(
        isOpen: true,
        message:
            'Abierto · cierra a las ${clockTimeFromMinutes(block.endMinute)}',
      );
    }
  }

  for (var offset = 1; offset <= 7; offset++) {
    final day = now.add(Duration(days: offset));
    final blocks = hours.blocksOn(day);
    if (blocks.isNotEmpty) {
      final relative = offset == 1 ? 'mañana' : _weekday(day.weekday);
      return ShopStatus(
        isOpen: false,
        message:
            'Cerrado · abre $relative a las ${clockTimeFromMinutes(blocks.first.startMinute)}',
      );
    }
  }
  return const ShopStatus(isOpen: false, message: 'Cerrado');
}

String _weekday(int weekday) => const {
  DateTime.monday: 'el lunes',
  DateTime.tuesday: 'el martes',
  DateTime.wednesday: 'el miércoles',
  DateTime.thursday: 'el jueves',
  DateTime.friday: 'el viernes',
  DateTime.saturday: 'el sábado',
  DateTime.sunday: 'el domingo',
}[weekday]!;
