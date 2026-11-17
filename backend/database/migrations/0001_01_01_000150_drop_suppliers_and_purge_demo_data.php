<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    private const DEMO_SKUS = [
        'TLS-001', 'TLS-002', 'TLS-003', 'EQP-001', 'EQP-002', 'CNS-001', 'CNS-002', 'MAT-001',
        'EIM-T-001', 'EIM-E-001', 'EIM-C-001', 'DRM-E-001', 'DRM-T-001', 'DRM-C-001',
        'HWM-E-001', 'HWM-C-001', 'HWM-C-002',
    ];

    private const DEMO_NOTIFICATION_MESSAGES = [
        'Extension Cord 50ft is running low on stock.',
        'Paint White 1Gal is out of stock.',
        'Your account has been set up successfully.',
    ];

    private const DEMO_ACTIVITY_DESCRIPTIONS = [
        'Admin logged in',
        'Created new item: Cordless Drill',
    ];

    private const ITEM_REFERENCE_TABLES = [
        'purchase_request_items', 'purchase_order_items', 'receiving_items', 'issuance_items',
        'borrowings', 'returns', 'maintenances', 'stock_movements', 'inventory_audit_items',
    ];

    public function up(): void
    {
        $demoItemIds = DB::table('items')->whereIn('sku', self::DEMO_SKUS)->pluck('id');

        if ($demoItemIds->isNotEmpty()) {
            DB::table('stock_movements')
                ->whereIn('item_id', $demoItemIds)
                ->where('reference', 'initial_stock')
                ->delete();

            foreach ($demoItemIds as $itemId) {
                if (! $this->isItemReferenced($itemId)) {
                    DB::table('items')->where('id', $itemId)->delete();
                }
            }
        }

        DB::table('notifications')->whereIn('message', self::DEMO_NOTIFICATION_MESSAGES)->delete();
        DB::table('activity_logs')->whereIn('description', self::DEMO_ACTIVITY_DESCRIPTIONS)->delete();

        if (! DB::table('qualifications')->where('code', 'EIM-NCII')->exists()) {
            DB::table('qualifications')->insert([
                'name' => 'Electrical Installation and Maintenance',
                'code' => 'EIM-NCII',
                'nc_level' => 'NC II',
                'description' => null,
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        Schema::table('items', function (Blueprint $table) {
            $table->dropConstrainedForeignId('supplier_id');
        });

        Schema::table('receivings', function (Blueprint $table) {
            $table->dropConstrainedForeignId('supplier_id');
        });

        Schema::table('purchase_orders', function (Blueprint $table) {
            $table->dropConstrainedForeignId('supplier_id');
        });

        Schema::dropIfExists('suppliers');
    }

    public function down(): void
    {
        Schema::create('suppliers', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('code')->nullable()->unique();
            $table->string('contact_person')->nullable();
            $table->string('email')->nullable();
            $table->string('phone')->nullable();
            $table->text('address')->nullable();
            $table->string('city')->nullable();
            $table->string('province')->nullable();
            $table->string('zip_code')->nullable();
            $table->string('tin')->nullable();
            $table->string('website')->nullable();
            $table->text('notes')->nullable();
            $table->boolean('is_active')->default(true);
            $table->decimal('rating', 2, 1)->nullable();
            $table->integer('total_purchases')->default(0);
            $table->timestamps();
        });

        Schema::table('items', function (Blueprint $table) {
            $table->foreignId('supplier_id')->nullable()->constrained()->nullOnDelete();
        });

        Schema::table('receivings', function (Blueprint $table) {
            $table->foreignId('supplier_id')->nullable()->constrained()->nullOnDelete();
        });

        Schema::table('purchase_orders', function (Blueprint $table) {
            $table->foreignId('supplier_id')->nullable()->constrained()->restrictOnDelete();
        });
    }

    private function isItemReferenced(int $itemId): bool
    {
        foreach (self::ITEM_REFERENCE_TABLES as $table) {
            if (Schema::hasTable($table) && DB::table($table)->where('item_id', $itemId)->exists()) {
                return true;
            }
        }

        return false;
    }
};
