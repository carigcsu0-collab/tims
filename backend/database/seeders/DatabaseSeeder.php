<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Category;
use App\Models\Supplier;
use App\Models\Item;
use App\Models\Notification;
use App\Models\ActivityLog;
use App\Models\StockMovement;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::create([
            'name' => 'System Administrator',
            'email' => 'admin@tims.local',
            'password' => 'password',
            'role' => 'admin',
            'is_active' => true,
            'position' => 'IT Manager',
            'department' => 'IT',
        ]);

        $manager = User::create([
            'name' => 'John Manager',
            'email' => 'manager@tims.local',
            'password' => 'password',
            'role' => 'manager',
            'is_active' => true,
            'position' => 'Inventory Manager',
            'department' => 'Operations',
        ]);

        $staff = User::create([
            'name' => 'Jane Staff',
            'email' => 'staff@tims.local',
            'password' => 'password',
            'role' => 'staff',
            'is_active' => true,
            'position' => 'Store Keeper',
            'department' => 'Operations',
        ]);

        $tools = Category::create(['name' => 'Tools', 'code' => 'TLS', 'is_active' => true]);
        $equipment = Category::create(['name' => 'Equipment', 'code' => 'EQP', 'is_active' => true]);
        $consumables = Category::create(['name' => 'Consumables', 'code' => 'CNS', 'is_active' => true]);
        $materials = Category::create(['name' => 'Materials', 'code' => 'MAT', 'is_active' => true]);

        Category::create(['name' => 'Power Tools', 'code' => 'PWT', 'parent_id' => $tools->id, 'is_active' => true]);
        Category::create(['name' => 'Hand Tools', 'code' => 'HDT', 'parent_id' => $tools->id, 'is_active' => true]);

        $supplier1 = Supplier::create([
            'name' => 'ABC Supply Co.',
            'code' => 'SUP001',
            'contact_person' => 'Alice Cooper',
            'email' => 'alice@abcsupply.com',
            'phone' => '555-0101',
            'address' => '123 Industrial Ave',
            'city' => 'Metro City',
            'is_active' => true,
            'rating' => 4.5,
        ]);

        $supplier2 = Supplier::create([
            'name' => 'XYZ Trading Inc.',
            'code' => 'SUP002',
            'contact_person' => 'Bob Smith',
            'email' => 'bob@xyztrading.com',
            'phone' => '555-0102',
            'address' => '456 Commerce Blvd',
            'city' => 'Metro City',
            'is_active' => true,
            'rating' => 4.0,
        ]);

        $items = [
            ['name' => 'Cordless Drill', 'sku' => 'TLS-001', 'type' => 'tool', 'status' => 'in_stock', 'category_id' => $tools->id, 'supplier_id' => $supplier1->id, 'quantity' => 25, 'minimum_stock' => 5, 'maximum_stock' => 50, 'reorder_level' => 10, 'unit_cost' => 150.00, 'unit' => 'pcs', 'brand' => 'DeWalt', 'model' => 'DCD777C2'],
            ['name' => 'Hammer', 'sku' => 'TLS-002', 'type' => 'tool', 'status' => 'in_stock', 'category_id' => $tools->id, 'supplier_id' => $supplier1->id, 'quantity' => 50, 'minimum_stock' => 10, 'maximum_stock' => 100, 'reorder_level' => 15, 'unit_cost' => 15.00, 'unit' => 'pcs', 'brand' => 'Stanley'],
            ['name' => 'Safety Helmet', 'sku' => 'EQP-001', 'type' => 'equipment', 'status' => 'in_stock', 'category_id' => $equipment->id, 'supplier_id' => $supplier2->id, 'quantity' => 100, 'minimum_stock' => 20, 'maximum_stock' => 200, 'reorder_level' => 30, 'unit_cost' => 25.00, 'unit' => 'pcs', 'brand' => '3M'],
            ['name' => 'Extension Cord 50ft', 'sku' => 'EQP-002', 'type' => 'equipment', 'status' => 'low_stock', 'category_id' => $equipment->id, 'supplier_id' => $supplier2->id, 'quantity' => 3, 'minimum_stock' => 5, 'maximum_stock' => 30, 'reorder_level' => 8, 'unit_cost' => 35.00, 'unit' => 'pcs'],
            ['name' => 'Screwdriver Set', 'sku' => 'TLS-003', 'type' => 'tool', 'status' => 'in_stock', 'category_id' => $tools->id, 'supplier_id' => $supplier1->id, 'quantity' => 30, 'minimum_stock' => 5, 'maximum_stock' => 60, 'reorder_level' => 10, 'unit_cost' => 20.00, 'unit' => 'set', 'brand' => 'Craftsman'],
            ['name' => 'Nails 2-inch', 'sku' => 'CNS-001', 'type' => 'consumable', 'status' => 'in_stock', 'category_id' => $consumables->id, 'supplier_id' => $supplier2->id, 'quantity' => 500, 'minimum_stock' => 100, 'maximum_stock' => 1000, 'reorder_level' => 200, 'unit_cost' => 0.05, 'unit' => 'pcs'],
            ['name' => 'Paint White 1Gal', 'sku' => 'CNS-002', 'type' => 'consumable', 'status' => 'out_of_stock', 'category_id' => $consumables->id, 'supplier_id' => $supplier2->id, 'quantity' => 0, 'minimum_stock' => 10, 'maximum_stock' => 100, 'reorder_level' => 15, 'unit_cost' => 45.00, 'unit' => 'gal', 'brand' => 'Behr'],
            ['name' => 'Plywood Sheet 4x8', 'sku' => 'MAT-001', 'type' => 'material', 'status' => 'in_stock', 'category_id' => $materials->id, 'supplier_id' => $supplier1->id, 'quantity' => 80, 'minimum_stock' => 20, 'maximum_stock' => 200, 'reorder_level' => 30, 'unit_cost' => 30.00, 'unit' => 'sheet'],
        ];

        foreach ($items as $itemData) {
            $itemData['total_value'] = $itemData['quantity'] * $itemData['unit_cost'];
            $itemData['is_active'] = true;
            Item::create($itemData);
        }

        Notification::create([
            'user_id' => $admin->id,
            'title' => 'Low Stock Alert',
            'message' => 'Extension Cord 50ft is running low on stock.',
            'type' => 'low_stock',
            'is_read' => false,
        ]);

        Notification::create([
            'user_id' => $admin->id,
            'title' => 'Out of Stock',
            'message' => 'Paint White 1Gal is out of stock.',
            'type' => 'low_stock',
            'is_read' => false,
        ]);

        Notification::create([
            'user_id' => $manager->id,
            'title' => 'Welcome to TIMS',
            'message' => 'Your account has been set up successfully.',
            'type' => 'general',
            'is_read' => true,
        ]);

        $drill = Item::where('sku', 'TLS-001')->first();
        StockMovement::create([
            'item_id' => $drill->id,
            'type' => 'adjustment',
            'quantity' => 25,
            'balance_after' => 25,
            'user_id' => $admin->id,
            'reference' => 'initial_stock',
            'notes' => 'Initial stock entry',
        ]);

        ActivityLog::create([
            'user_id' => $admin->id,
            'action' => 'login',
            'module' => 'auth',
            'description' => 'Admin logged in',
            'ip_address' => '127.0.0.1',
        ]);

        ActivityLog::create([
            'user_id' => $manager->id,
            'action' => 'create',
            'module' => 'items',
            'description' => 'Created new item: Cordless Drill',
            'ip_address' => '127.0.0.1',
        ]);

        $this->call(QualificationSeeder::class);
    }
}
