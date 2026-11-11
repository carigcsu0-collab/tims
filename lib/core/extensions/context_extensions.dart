import 'package:flutter/material.dart';

/// Extension on [BuildContext] providing quick access to common MediaQuery values.
extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  double get statusBarHeight => MediaQuery.paddingOf(this).top;
  double get bottomPadding => MediaQuery.paddingOf(this).bottom;

  /// Returns true if the screen width is below the tablet breakpoint (600dp).
  bool get isPhone => screenWidth < 600;

  /// Returns true if the screen width is between tablet and desktop (600-1200dp).
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;

  /// Returns true if the screen width is at or above the desktop breakpoint (1200dp).
  bool get isDesktop => screenWidth >= 1200;

  /// Returns the appropriate content padding based on screen size.
  EdgeInsets get responsivePadding =>
      isDesktop ? const EdgeInsets.all(32) : const EdgeInsets.all(16);

  /// Returns the max content width for centered layouts on large screens.
  double get maxContentWidth => isDesktop ? 1200 : double.infinity;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}
