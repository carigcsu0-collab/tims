<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class RoleController extends Controller
{
    private const ROLES = [
        ['name' => 'admin', 'label' => 'Administrator', 'description' => 'Full system access'],
        ['name' => 'manager', 'label' => 'Manager', 'description' => 'Manage inventory, approve requests'],
        ['name' => 'staff', 'label' => 'Staff', 'description' => 'Basic inventory operations'],
    ];

    private const PERMISSIONS = [
        ['name' => 'items.view', 'label' => 'View Items', 'module' => 'items'],
        ['name' => 'items.create', 'label' => 'Create Items', 'module' => 'items'],
        ['name' => 'items.edit', 'label' => 'Edit Items', 'module' => 'items'],
        ['name' => 'items.delete', 'label' => 'Delete Items', 'module' => 'items'],
        ['name' => 'purchase-requests.view', 'label' => 'View Purchase Requests', 'module' => 'purchase-requests'],
        ['name' => 'purchase-requests.create', 'label' => 'Create Purchase Requests', 'module' => 'purchase-requests'],
        ['name' => 'purchase-requests.approve', 'label' => 'Approve Purchase Requests', 'module' => 'purchase-requests'],
        ['name' => 'purchase-orders.view', 'label' => 'View Purchase Orders', 'module' => 'purchase-orders'],
        ['name' => 'purchase-orders.create', 'label' => 'Create Purchase Orders', 'module' => 'purchase-orders'],
        ['name' => 'receivings.view', 'label' => 'View Receivings', 'module' => 'receivings'],
        ['name' => 'receivings.create', 'label' => 'Create Receivings', 'module' => 'receivings'],
        ['name' => 'issuances.view', 'label' => 'View Issuances', 'module' => 'issuances'],
        ['name' => 'issuances.create', 'label' => 'Create Issuances', 'module' => 'issuances'],
        ['name' => 'borrowings.view', 'label' => 'View Borrowings', 'module' => 'borrowings'],
        ['name' => 'borrowings.create', 'label' => 'Create Borrowings', 'module' => 'borrowings'],
        ['name' => 'borrowings.approve', 'label' => 'Approve Borrowings', 'module' => 'borrowings'],
        ['name' => 'maintenances.view', 'label' => 'View Maintenance', 'module' => 'maintenances'],
        ['name' => 'maintenances.create', 'label' => 'Create Maintenance', 'module' => 'maintenances'],
        ['name' => 'reports.view', 'label' => 'View Reports', 'module' => 'reports'],
        ['name' => 'users.view', 'label' => 'View Users', 'module' => 'users'],
        ['name' => 'users.create', 'label' => 'Create Users', 'module' => 'users'],
        ['name' => 'users.edit', 'label' => 'Edit Users', 'module' => 'users'],
        ['name' => 'users.delete', 'label' => 'Delete Users', 'module' => 'users'],
        ['name' => 'settings.view', 'label' => 'View Settings', 'module' => 'settings'],
        ['name' => 'settings.edit', 'label' => 'Edit Settings', 'module' => 'settings'],
    ];

    private const ROLE_PERMISSIONS = [
        'admin' => ['*'],
        'manager' => [
            'items.view', 'items.create', 'items.edit',
            'purchase-requests.view', 'purchase-requests.create', 'purchase-requests.approve',
            'purchase-orders.view', 'purchase-orders.create',
            'receivings.view', 'receivings.create',
            'issuances.view', 'issuances.create',
            'borrowings.view', 'borrowings.create', 'borrowings.approve',
            'maintenances.view', 'maintenances.create',
            'reports.view', 'users.view',
        ],
        'staff' => [
            'items.view',
            'purchase-requests.view', 'purchase-requests.create',
            'issuances.view', 'issuances.create',
            'borrowings.view', 'borrowings.create',
            'maintenances.view',
        ],
    ];

    public function roles()
    {
        return response()->json(self::ROLES);
    }

    public function permissions()
    {
        return response()->json(self::PERMISSIONS);
    }

    public function rolePermissions($role)
    {
        $permissions = self::ROLE_PERMISSIONS[$role] ?? [];
        return response()->json([
            'role' => $role,
            'permissions' => $permissions,
        ]);
    }
}
