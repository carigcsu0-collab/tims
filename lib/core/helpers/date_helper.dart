import 'package:intl/intl.dart';

/// Utility class for date/time formatting and parsing.
class DateHelper {
  DateHelper._();

  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy hh:mm a');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  /// Formats a [DateTime] to 'MMM dd, yyyy' (e.g., Jan 15, 2025).
  static String formatDate(DateTime? date) {
    if (date == null) return '--';
    return _dateFormat.format(date);
  }

  /// Formats a [DateTime] to 'MMM dd, yyyy hh:mm a'.
  static String formatDateTime(DateTime? date) {
    if (date == null) return '--';
    return _dateTimeFormat.format(date);
  }

  /// Formats a [DateTime] to 'hh:mm a'.
  static String formatTime(DateTime? time) {
    if (time == null) return '--';
    return _timeFormat.format(time);
  }

  /// Formats a [DateTime] to 'yyyy-MM-dd' for API submission.
  static String toIsoDate(DateTime date) => _isoFormat.format(date);

  /// Parses an ISO date string.
  static DateTime? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// Returns a human-readable relative time (e.g., '2 hours ago').
  static String timeAgo(DateTime? date) {
    if (date == null) return '--';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  /// Returns the number of days until [date], or 0 if past.
  static int daysUntil(DateTime date) {
    final now = DateTime.now();
    return date.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  /// Returns true if [date] is today.
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
