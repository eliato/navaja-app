DateTime? reminderTimeFor({
  required DateTime appointmentStart,
  required DateTime now,
}) {
  const preferredLeadTimes = [
    Duration(days: 1),
    Duration(hours: 1),
    Duration(minutes: 15),
  ];
  for (final leadTime in preferredLeadTimes) {
    final reminder = appointmentStart.subtract(leadTime);
    if (reminder.isAfter(now)) return reminder;
  }

  final immediateReminder = now.add(const Duration(minutes: 1));
  return immediateReminder.isBefore(appointmentStart)
      ? immediateReminder
      : null;
}
