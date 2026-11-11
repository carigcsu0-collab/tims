<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('borrowings', function (Blueprint $table) {
            $table->id();
            $table->string('borrow_number')->unique();
            $table->foreignId('item_id')->constrained()->restrictOnDelete();
            $table->foreignId('borrower_id')->constrained('users')->restrictOnDelete();
            $table->enum('status', ['requested', 'approved', 'borrowed', 'returned', 'overdue', 'rejected', 'cancelled'])->default('requested');
            $table->date('borrow_date');
            $table->date('expected_return_date')->nullable();
            $table->date('actual_return_date')->nullable();
            $table->integer('quantity')->default(1);
            $table->text('purpose')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('condition_out')->nullable();
            $table->string('condition_in')->nullable();
            $table->text('notes')->nullable();
            $table->foreignId('return_id')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('borrowings');
    }
};
