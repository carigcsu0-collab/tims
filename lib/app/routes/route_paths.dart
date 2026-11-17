/// Route path constants used by [GoRouter].
class RoutePaths {
  RoutePaths._();

  // Auth
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main (with shell)
  static const String dashboard = '/dashboard';
  static const String inventory = '/inventory';
  static const String categories = '/categories';
  static const String items = '/items';
  static const String toolsEquipment = '/tools-equipment';
  static const String consumables = '/consumables';
  static const String qualifications = '/qualifications';
  static const String purchaseRequests = '/purchase-requests';
  static const String purchaseOrders = '/purchase-orders';
  static const String receiving = '/receiving';
  static const String issuance = '/issuance';
  static const String borrowing = '/borrowing';
  static const String returns = '/returns';
  static const String maintenance = '/maintenance';
  static const String reports = '/reports';
  static const String notifications = '/notifications';
  static const String activityLogs = '/activity-logs';
  static const String users = '/users';
  static const String roles = '/roles';
  static const String settings = '/settings';
  static const String profile = '/profile';

  // Detail routes
  static String itemDetail(int id) => '/items/$id';
  static String categoryDetail(int id) => '/categories/$id';
  static String purchaseRequestDetail(int id) => '/purchase-requests/$id';
  static String purchaseOrderDetail(int id) => '/purchase-orders/$id';
  static String borrowingDetail(int id) => '/borrowing/$id';
  static String maintenanceDetail(int id) => '/maintenance/$id';
}

/// Route names for navigation.
class RouteNames {
  RouteNames._();

  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';
  static const String dashboard = 'dashboard';
  static const String inventory = 'inventory';
  static const String categories = 'categories';
  static const String items = 'items';
  static const String toolsEquipment = 'tools-equipment';
  static const String consumables = 'consumables';
  static const String qualifications = 'qualifications';
  static const String purchaseRequests = 'purchase-requests';
  static const String purchaseOrders = 'purchase-orders';
  static const String receiving = 'receiving';
  static const String issuance = 'issuance';
  static const String borrowing = 'borrowing';
  static const String returns = 'returns';
  static const String maintenance = 'maintenance';
  static const String reports = 'reports';
  static const String notifications = 'notifications';
  static const String activityLogs = 'activity-logs';
  static const String users = 'users';
  static const String roles = 'roles';
  static const String settings = 'settings';
  static const String profile = 'profile';
}
