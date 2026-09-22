import 'package:intl/intl.dart';

/// Human-friendly timestamp formatting utilities for operational feeds,
/// incident tracking, and audit activity.
class TimeUtils {
  TimeUtils._();

  /// Formats [dateTime] into relative operational strings:
  /// - 'Just now' (< 1 min)
  /// - '5 min ago' (< 60 mins)
  /// - 'Today, 10:42 AM' (today)
  /// - 'Yesterday, 7:30 PM' (yesterday)
  /// - '22 Sep 2026, 10:42 AM' (earlier)
  static String formatHumanFriendly(DateTime? dateTime, [DateTime? clockNow]) {
    if (dateTime == null) return 'Recent';

    final now = clockNow ?? DateTime.now();
    final difference = now.difference(dateTime);

    // If timestamp is in future or less than 1 minute ago
    if (difference.isNegative || difference.inSeconds < 60) {
      return 'Just now';
    }

    // Within current hour
    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'min' : 'min'} ago';
    }

    final isToday = dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;

    final timeString = DateFormat('h:mm a').format(dateTime);

    if (isToday) {
      return 'Today, $timeString';
    }

    if (isYesterday) {
      return 'Yesterday, $timeString';
    }

    // Within same calendar year
    if (dateTime.year == now.year) {
      return DateFormat('d MMM, h:mm a').format(dateTime);
    }

    // Different year
    return DateFormat('d MMM yyyy, h:mm a').format(dateTime);
  }

  /// Formats [dateTime] to human-friendly relative string.
  static String formatRelative(DateTime? dateTime) => formatHumanFriendly(dateTime);

  /// Returns the exact ISO-standard or full audit timestamp string.
  static String formatExact(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('dd MMM yyyy, hh:mm:ss a').format(dateTime);
  }
}
