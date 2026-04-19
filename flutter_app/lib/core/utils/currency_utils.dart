import 'package:intl/intl.dart';

/// Currency formatting utilities.
///
/// All monetary amounts are stored as `int` (cents/分) to avoid
/// floating-point precision issues. Display using these helpers.
abstract final class CurrencyUtils {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'zh_CN',
    symbol: '¥',
    decimalDigits: 2,
  );

  /// Format cents to display string: `¥12,345.67`
  static String formatCents(int cents) =>
      _currencyFormat.format(cents / 100);

  /// Format a double amount: `¥12,345.67`
  static String formatAmount(double amount) =>
      _currencyFormat.format(amount);
}
