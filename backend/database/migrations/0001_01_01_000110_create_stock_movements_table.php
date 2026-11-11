<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('stock_movements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('item_id')->constrained()->restrictOnDelete();
            $table->enum('type', ['purchase', 'issuance', 'borrowing', 'return_in', 'return_out', 'adjustment', 'transfer', 'damage', 'disposal']);
            $table->integer('quantity');
            $table->integer('balance_after')->default(0);
            $table->foreignId('user_id')->constrained('users')->restrictOnDelete();
            $table->string('reference')->nullable();
            $table->unsignedBigInteger('reference_id')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('stock_movements');
    }
};
