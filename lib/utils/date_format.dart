const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Example: 10:30 AM
String formatTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

/// Example: Today, 10:30 AM, Tomorrow, 4:00 PM, or May 24, 4:00 PM
String formatDeadline(DateTime deadline, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final today = DateTime.utc(current.year, current.month, current.day);
  final day = DateTime.utc(deadline.year, deadline.month, deadline.day);
  final daysAhead = day.difference(today).inDays;
  final daysBehind = today.difference(day).inDays;
  final time = formatTime(deadline);

  if (daysAhead == 0) return 'Today, $time';
  if (daysAhead == 1) return 'Tomorrow, $time';
  if (daysBehind == 1) return 'Yesterday, $time';
  return '${_months[deadline.month - 1]} ${deadline.day}, $time';
}
