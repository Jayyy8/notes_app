const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> _weekdays = <String>[
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday',
];

/// "9:05 AM" today, "Yesterday", a weekday within the last week, then "Oct 3"
/// or "Oct 3, 2025". Pass [now] in tests.
String formatNoteDate(DateTime date, {DateTime? now}) {
  final current = now ?? DateTime.now();
  // Compare calendar days in UTC so daylight saving shifts can't skew the diff.
  final today = DateTime.utc(current.year, current.month, current.day);
  final day = DateTime.utc(date.year, date.month, date.day);
  final diffDays = today.difference(day).inDays;

  if (diffDays == 0) return _time(date);
  if (diffDays == 1) return 'Yesterday';
  if (diffDays > 1 && diffDays < 7) return _weekdays[date.weekday - 1];
  if (date.year == current.year) {
    return '${_months[date.month - 1]} ${date.day}';
  }
  return '${_months[date.month - 1]} ${date.day}, ${date.year}';
}

String _time(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $suffix';
}