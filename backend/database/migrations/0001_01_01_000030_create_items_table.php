<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('items', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('sku')->unique();
            $table->string('barcode')->nullable();
            $table->enum('type', ['tool', 'equipment', 'consumable', 'material', 'asset']);
            $table->enum('status', ['in_stock', 'low_stock', 'out_of_stock', 'reserved', 'damaged', 'deprecated'])->default('in_stock');
            $table->string('unit')->default('pcs');
            $table->foreignId('category_id')->nullable()->constrained()->nullOnDelete();
            $table->text('description')->nullable();
            $table->string('brand')->nullable();
            $table->string('model')->nullable();
            $table->string('serial_number')->nullable();
            $table->integer('quantity')->default(0);
            $table->integer('minimum_stock')->default(0);
            $table->integer('maximum_stock')->default(0);
            $table->integer('reorder_level')->default(0);
            $table->decimal('unit_cost', 12, 2)->default(0);
            $table->decimal('total_value', 12, 2)->default(0);
            $table->string('location')->nullable();
            $table->string('image_url')->nullable();
            $table->foreignId('supplier_id')->nullable()->constrained()->nullOnDelete();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('items');
    }
};
