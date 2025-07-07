
extension DateTimeAgo on DateTime {
  /// Returns `true` if this [DateTime] is today.
  bool isToday() {
    final DateTime now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns a string representing the time elapsed since this [DateTime].
  String timeAgo() {
    final Duration duration = DateTime.now().difference(this);
    if (duration.inDays >= 365) {
      final int years = (duration.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
    if (duration.inDays >= 30) {
      final int months = (duration.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} ago';
    }
    if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} ago';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min${duration.inMinutes > 1 ? 's' : ''} ago';
    }
    if (duration.inSeconds > 0) {
      return '${duration.inSeconds} sec${duration.inSeconds > 1 ? 's' : ''} ago';
    }
    return 'Just now';
  }

  /// Returns a string representing the date and time in a readable format.
  /// ex. "MM/DD/YYYY"
  String readableDateWithSlash() {
    return '${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}/${year.toString().padLeft(4, '0')}';
  }

  /// Returns a string representing the date and time in a readable format.
  /// ex. "MM/DD/YYYY"
  String readableDateWithDash() {
    return '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}-${year.toString().padLeft(4, '0')}';
  }

  /// Returns a string representing the time in a readable format.
  /// ex. "HH:MM:SS"
  String readableTime() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  }

  /// Returns a string representing the date and time in a readable format.
  /// ex. "MM/DD/YYYY HH:MM:SS"
  String readableDateTime() {
    return '${readableDateWithSlash()} ${readableTime()}';
  }

}

DateTime parseDateTime(String dateTimeString) {
  // Adjust the format as per your `joinedDate` string format, e.g., "YYYY-MM-DD HH:MM:SS"
  return DateTime.parse(dateTimeString);
}
