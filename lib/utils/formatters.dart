import 'package:intl/intl.dart';

/// Human-friendly date helpers used across the UI.
class Formatters {
  Formatters._();

  static final _time = DateFormat('h:mm a');
  static final _monthDay = DateFormat('MMM d');
  static final _full = DateFormat('MMM d, yyyy');
  static final _headerDate = DateFormat('EEEE, MMMM d');

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// "Today, 4:00 PM" · "Tomorrow, 9:00 AM" · "Yesterday, 2:00 PM" ·
  /// "May 23, 11:00 AM" · "Jan 3, 2027, 11:00 AM" (other years).
  static String deadline(DateTime date, {DateTime? now}) {
    final today = _day(now ?? DateTime.now());
    final diff = _day(date).difference(today).inDays;
    final time = _time.format(date);
    if (diff == 0) return 'Today, $time';
    if (diff == 1) return 'Tomorrow, $time';
    if (diff == -1) return 'Yesterday, $time';
    if (date.year != today.year) return '${_full.format(date)}, $time';
    return '${_monthDay.format(date)}, $time';
  }

  static String headerDate(DateTime date) => _headerDate.format(date);

  /// "just now" · "28m ago" · "3h ago" · "2d ago".
  static String timeAgo(DateTime date, {DateTime? now}) {
    final d = (now ?? DateTime.now()).difference(date);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return _monthDay.format(date);
  }

  /// "2d 4h" / "3h 20m" / "15m" — used for SLA time remaining.
  static String duration(Duration d) {
    final abs = d.abs();
    if (abs.inDays > 0) return '${abs.inDays}d ${abs.inHours % 24}h';
    if (abs.inHours > 0) return '${abs.inHours}h ${abs.inMinutes % 60}m';
    return '${abs.inMinutes}m';
  }

  static String greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
}
