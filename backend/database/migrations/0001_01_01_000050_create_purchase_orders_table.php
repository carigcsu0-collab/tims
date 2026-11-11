<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('purchase_orders', function (Blueprint $table) {
            $table->id();
            $table->string('po_number')->unique();
            $table->enum('status', ['draft', 'sent', 'acknowledged', 'partial', 'received', 'cancelled'])->default('draft');
            $table->foreignId('supplier_id')->constrained()->restrictOnDelete();
            $table->decimal('total_amount', 14, 2)->default(0);
            $table->foreignId('purchase_request_id')->nullable();
            $table->date('expected_delivery_date')->nullable();
            $table->date('actual_delivery_date')->nullable();
            $table->string('payment_terms')->nullable();
            $table->text('delivery_address')->nullable();
            $table->text('notes')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });

        Schema::create('purchase_order_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('purchase_order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('item_id')->constrained()->restrictOnDelete();
            $table->integer('quantity_ordered')->default(0);
            $table->integer('quantity_received')->default(0);
            $table->decimal('unit_cost', 12, 2)->default(0);
            $table->string('unit')->default('pcs');
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('purchase_order_items');
        Schema::dropIfExists('purchase_orders');
    }
};
