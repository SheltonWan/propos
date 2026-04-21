import 'package:intl/intl.dart';

/// Date formatting utilities.
///
/// All date display in the app must use these helpers.
/// Business date calculations (WALE, overdue days) are done on the backend.
abstract final class AppDateUtils {
  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  /// Format a [DateTime] to `yyyy-MM-dd` in local timezone.
  static String formatDate(DateTime dateTime) =>
      _dateFormat.format(dateTime.toLocal());

  /// Format a [DateTime] to `yyyy-MM-dd HH:mm` in local timezone.
  static String formatDateTime(DateTime dateTime) =>
      _dateTimeFormat.format(dateTime.toLocal());

  /// Parse an ISO 8601 date string from the API.
  static DateTime parseIso(String isoString) => DateTime.parse(isoString);
}
