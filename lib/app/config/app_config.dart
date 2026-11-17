import 'package:flutter/material.dart';

/// Application-wide configuration constants.
class AppConfig {
  AppConfig._();

  /// App name displayed in UI.
  static const String appName = 'CSU TVET IMS';

  /// Full app name.
  static const String appFullName =
      'CSU TVET Office Inventory Management System';

  /// Office header lines used on screens and printable documents.
  static const String universityName = 'CAGAYAN STATE UNIVERSITY';
  static const String officeName = 'TVET Office';

  /// CSU logo used on printed reports.
  static const String logoAsset = 'assets/images/csu-logo.jpeg';

  /// App version.
  static const String appVersion = '1.0.0';

  /// Organization.
  static const String organization = 'CAGAYAN STATE UNIVERSITY-CARIG CAMPUS';

  /// API base URL (should match .env API_BASE_URL).
  static const String apiBaseUrl = 'https://dtc-main-pc.tail9ac631.ts.net/tims/api/v1';

  /// API version.
  static const String apiVersion = 'v1';

  /// Default items per page for paginated lists.
  static const int defaultPageSize = 15;

  /// Breakpoints for responsive layout.
  static const double phoneBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Sidebar widths.
  static const double sidebarCollapsedWidth = 72;
  static const double sidebarExpandedWidth = 280;

  /// Animation durations.
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  /// Session timeout (in minutes).
  static const int sessionTimeoutMinutes = 30;
}

/// Application color palette for TESDA/TIMS branding.
class AppColors {
  AppColors._();

  // Primary - TESDA Blue
  static const Color primary = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF5472D3);
  static const Color primaryDark = Color(0xFF002171);

  // Secondary - Gold/Amber
  static const Color secondary = Color(0xFFF9A825);
  static const Color secondaryLight = Color(0xFFFFD95A);
  static const Color secondaryDark = Color(0xFFC17900);

  // Status colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF0288D1);

  // Neutral
  static const Color surface = Color(0xFFF5F5F5);
  static const Color background = Color(0xFFFAFAFA);
}
