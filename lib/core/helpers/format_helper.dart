import 'package:intl/intl.dart';

/// Utility class for currency and number formatting.
class FormatHelper {
  FormatHelper._();

  static final NumberFormat _currencyFormat =
      NumberFormat.currency(symbol: '₱', decimalDigits: 2);
  static final NumberFormat _numberFormat = NumberFormat.decimalPattern();
  static final NumberFormat _percentFormat = NumberFormat.percentPattern();

  /// Formats a number as Philippine Peso currency (e.g., ₱1,234.56).
  static String currency(double value) => _currencyFormat.format(value);

  /// Formats a number with thousand separators.
  static String number(num value) => _numberFormat.format(value);

  /// Formats a value as percentage.
  static String percent(double value) => _percentFormat.format(value);

  /// Formats a quantity with its unit.
  static String quantity(int qty, String unit) => '$qty $unit';

  /// Truncates text to [maxChars] and appends '...' if needed.
  static String truncate(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}...';
  }

  /// Formats a file size in bytes to a human-readable string.
  static String fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
