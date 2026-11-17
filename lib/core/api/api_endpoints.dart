/// Centralized API endpoint constants for the TIMS Laravel REST API.
class ApiEndpoints {
  ApiEndpoints._();

  // Base
  static const String apiVersion = '/v1';

  // Authentication
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String refreshToken = '/auth/refresh';
  static const String currentUser = '/auth/me';

  // Dashboard
  static const String dashboardStats = '/dashboard/stats';
  static const String dashboardCharts = '/dashboard/charts';
  static const String dashboardRecentActivity = '/dashboard/recent-activity';

  // Categories
  static const String categories = '/categories';
  static String categoryById(int id) => '/categories/$id';

  // Items
  static const String items = '/items';
  static String itemById(int id) => '/items/$id';
  static const String itemsLowStock = '/items/low-stock';
  static const String itemsSearch = '/items/search';

  // Qualifications (TVET programs)
  static const String qualifications = '/qualifications';
  static String qualificationById(int id) => '/qualifications/$id';

  // Tools & Equipment
  static const String toolsEquipment = '/tools-equipment';
  static String toolById(int id) => '/tools-equipment/$id';

  // Consumables
  static const String consumables = '/consumables';
  static String consumableById(int id) => '/consumables/$id';

  // Procurement
  static const String purchaseRequests = '/purchase-requests';
  static String purchaseRequestById(int id) => '/purchase-requests/$id';
  static const String purchaseOrders = '/purchase-orders';
  static String purchaseOrderById(int id) => '/purchase-orders/$id';

  // Receiving
  static const String receivings = '/receivings';
  static String receivingById(int id) => '/receivings/$id';

  // Issuance
  static const String issuances = '/issuances';
  static String issuanceById(int id) => '/issuances/$id';

  // Borrowing
  static const String borrowings = '/borrowings';
  static String borrowingById(int id) => '/borrowings/$id';

  // Returns
  static const String returns = '/returns';
  static String returnById(int id) => '/returns/$id';

  // Maintenance
  static const String maintenances = '/maintenances';
  static String maintenanceById(int id) => '/maintenances/$id';

  // Asset Management
  static const String assets = '/assets';
  static String assetById(int id) => '/assets/$id';

  // Inventory Audit
  static const String audits = '/inventory-audits';
  static String auditById(int id) => '/inventory-audits/$id';

  // Stock Movement
  static const String stockMovements = '/stock-movements';
  static const String stockMovementByItem = '/stock-movements/by-item';

  // Reports
  static const String reports = '/reports';
  static const String reportsInventory = '/reports/inventory';
  static const String reportsInventorySummary = '/reports/inventory-summary';
  static const String reportsCondition = '/reports/condition';
  static const String reportsIssuance = '/reports/issuance';
  static const String reportsProcurement = '/reports/procurement';
  static const String reportsBorrowing = '/reports/borrowing';
  static const String reportsMaintenance = '/reports/maintenance';
  static const String reportsAudit = '/reports/audit';
  static const String reportsStockMovement = '/reports/stock-movement';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationById(int id) => '/notifications/$id';
  static const String notificationsMarkAllRead = '/notifications/mark-all-read';

  // User Management
  static const String users = '/users';
  static String userById(int id) => '/users/$id';

  // Roles & Permissions
  static const String roles = '/roles';
  static const String permissions = '/permissions';

  // Activity Logs
  static const String activityLogs = '/activity-logs';

  // Settings
  static const String settings = '/settings';

  // Profile
  static const String profile = '/profile';
  static const String profileUpdatePassword = '/profile/update-password';
}
