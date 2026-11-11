/// Utility class for input validation.
class ValidatorHelper {
  ValidatorHelper._();

  /// Validates an email address.
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');
    if (!regex.hasMatch(value)) return 'Enter a valid email address';
    return null;
  }

  /// Validates a required field.
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  /// Validates a password with minimum length.
  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// Validates that two passwords match.
  static String? confirmPassword(String? value, String? original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  /// Validates a phone number (Philippine format).
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^(\+63|0)?[0-9]{10}$');
    if (!regex.hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Validates a numeric field.
  static String? numeric(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    if (double.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }
    return null;
  }

  /// Validates a minimum value.
  static String? minValue(String? value, double min,
      {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    final numValue = double.tryParse(value);
    if (numValue == null) return '$fieldName must be a valid number';
    if (numValue < min) return '$fieldName must be at least $min';
    return null;
  }

  /// Validates a maximum length.
  static String? maxLength(String? value, int max,
      {String fieldName = 'This field'}) {
    if (value == null) return null;
    if (value.length > max) {
      return '$fieldName must not exceed $max characters';
    }
    return null;
  }

  /// Validates a SKU/code format.
  static String? sku(String? value) {
    if (value == null || value.isEmpty) return 'SKU is required';
    if (value.length < 3) return 'SKU must be at least 3 characters';
    if (!RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(value)) {
      return 'SKU can only contain letters, numbers, hyphens, and underscores';
    }
    return null;
  }
}
