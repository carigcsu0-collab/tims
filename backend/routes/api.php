<?php

use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // Auth
    Route::post('/auth/login', [App\Http\Controllers\Api\AuthController::class, 'login']);
    Route::post('/auth/register', [App\Http\Controllers\Api\AuthController::class, 'register']);
    Route::post('/auth/forgot-password', [App\Http\Controllers\Api\AuthController::class, 'forgotPassword']);
    Route::post('/auth/reset-password', [App\Http\Controllers\Api\AuthController::class, 'resetPassword']);
    Route::post('/auth/verify-email', [App\Http\Controllers\Api\AuthController::class, 'verifyEmail']);

    Route::middleware('auth:sanctum')->group(function () {
        // Auth - authenticated
        Route::post('/auth/logout', [App\Http\Controllers\Api\AuthController::class, 'logout']);
        Route::post('/auth/refresh', [App\Http\Controllers\Api\AuthController::class, 'refresh']);
        Route::get('/auth/me', [App\Http\Controllers\Api\AuthController::class, 'me']);

        // Dashboard
        Route::get('/dashboard/stats', [App\Http\Controllers\Api\DashboardController::class, 'stats']);
        Route::get('/dashboard/charts', [App\Http\Controllers\Api\DashboardController::class, 'charts']);
        Route::get('/dashboard/recent-activity', [App\Http\Controllers\Api\DashboardController::class, 'recentActivity']);

        // Categories
        Route::apiResource('categories', App\Http\Controllers\Api\CategoryController::class);

        // Items
        Route::get('/items/low-stock', [App\Http\Controllers\Api\ItemController::class, 'lowStock']);
        Route::get('/items/search', [App\Http\Controllers\Api\ItemController::class, 'search']);
        Route::apiResource('items', App\Http\Controllers\Api\ItemController::class);

        // Qualifications (TVET training programs)
        Route::apiResource('qualifications', App\Http\Controllers\Api\QualificationController::class);

        // Purchase Requests
        Route::apiResource('purchase-requests', App\Http\Controllers\Api\PurchaseRequestController::class);
        Route::post('/purchase-requests/{id}/approve', [App\Http\Controllers\Api\PurchaseRequestController::class, 'approve']);
        Route::post('/purchase-requests/{id}/reject', [App\Http\Controllers\Api\PurchaseRequestController::class, 'reject']);

        // Purchase Orders
        Route::apiResource('purchase-orders', App\Http\Controllers\Api\PurchaseOrderController::class);

        // Receivings
        Route::apiResource('receivings', App\Http\Controllers\Api\ReceivingController::class);

        // Issuances
        Route::apiResource('issuances', App\Http\Controllers\Api\IssuanceController::class);

        // Borrowings
        Route::apiResource('borrowings', App\Http\Controllers\Api\BorrowingController::class);
        Route::post('/borrowings/{id}/approve', [App\Http\Controllers\Api\BorrowingController::class, 'approve']);
        Route::post('/borrowings/{id}/reject', [App\Http\Controllers\Api\BorrowingController::class, 'reject']);
        Route::post('/borrowings/{id}/return', [App\Http\Controllers\Api\BorrowingController::class, 'returnItem']);

        // Returns
        Route::apiResource('returns', App\Http\Controllers\Api\ReturnController::class);

        // Maintenance
        Route::apiResource('maintenances', App\Http\Controllers\Api\MaintenanceController::class);
        Route::post('/maintenances/{id}/complete', [App\Http\Controllers\Api\MaintenanceController::class, 'complete']);

        // Stock Movements
        Route::get('/stock-movements', [App\Http\Controllers\Api\StockMovementController::class, 'index']);
        Route::get('/stock-movements/by-item', [App\Http\Controllers\Api\StockMovementController::class, 'byItem']);

        // Reports
        Route::get('/reports/inventory-summary', [App\Http\Controllers\Api\ReportController::class, 'inventorySummary']);
        Route::get('/reports/condition', [App\Http\Controllers\Api\ReportController::class, 'condition']);
        Route::get('/reports/issuance', [App\Http\Controllers\Api\ReportController::class, 'issuance']);
        Route::get('/reports/inventory', [App\Http\Controllers\Api\ReportController::class, 'inventory']);
        Route::get('/reports/procurement', [App\Http\Controllers\Api\ReportController::class, 'procurement']);
        Route::get('/reports/borrowing', [App\Http\Controllers\Api\ReportController::class, 'borrowing']);
        Route::get('/reports/maintenance', [App\Http\Controllers\Api\ReportController::class, 'maintenance']);
        Route::get('/reports/audit', [App\Http\Controllers\Api\ReportController::class, 'audit']);
        Route::get('/reports/stock-movement', [App\Http\Controllers\Api\ReportController::class, 'stockMovement']);

        // Notifications
        Route::get('/notifications', [App\Http\Controllers\Api\NotificationController::class, 'index']);
        Route::post('/notifications/mark-all-read', [App\Http\Controllers\Api\NotificationController::class, 'markAllRead']);
        Route::patch('/notifications/{id}', [App\Http\Controllers\Api\NotificationController::class, 'markAsRead']);
        Route::delete('/notifications/{id}', [App\Http\Controllers\Api\NotificationController::class, 'destroy']);

        // Users
        Route::apiResource('users', App\Http\Controllers\Api\UserController::class);

        // Activity Logs
        Route::get('/activity-logs', [App\Http\Controllers\Api\ActivityLogController::class, 'index']);

        // Profile
        Route::get('/profile', [App\Http\Controllers\Api\ProfileController::class, 'show']);
        Route::put('/profile', [App\Http\Controllers\Api\ProfileController::class, 'update']);
        Route::put('/profile/update-password', [App\Http\Controllers\Api\ProfileController::class, 'updatePassword']);

        // Tools & Equipment
        Route::apiResource('tools-equipment', App\Http\Controllers\Api\ToolsEquipmentController::class);

        // Consumables
        Route::apiResource('consumables', App\Http\Controllers\Api\ConsumableController::class);

        // Assets
        Route::apiResource('assets', App\Http\Controllers\Api\AssetController::class);

        // Inventory Audits
        Route::apiResource('inventory-audits', App\Http\Controllers\Api\InventoryAuditController::class);
        Route::post('/inventory-audits/{id}/complete', [App\Http\Controllers\Api\InventoryAuditController::class, 'complete']);

        // Roles & Permissions
        Route::get('/roles', [App\Http\Controllers\Api\RoleController::class, 'roles']);
        Route::get('/permissions', [App\Http\Controllers\Api\RoleController::class, 'permissions']);
        Route::get('/roles/{role}/permissions', [App\Http\Controllers\Api\RoleController::class, 'rolePermissions']);

        // Settings
        Route::get('/settings', [App\Http\Controllers\Api\SettingsController::class, 'index']);
        Route::put('/settings', [App\Http\Controllers\Api\SettingsController::class, 'update']);
    });
});
