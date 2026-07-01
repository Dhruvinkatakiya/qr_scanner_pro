import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  /// Short relative time such as "just now", "5m", "3h", "2d", else a date.
  static String relative(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.yMMMd().format(time);
  }

  static String fullDate(DateTime time) =>
      DateFormat.yMMMEd().add_jm().format(time);

  static String monthYear(DateTime time) => DateFormat.yMMMM().format(time);
}
