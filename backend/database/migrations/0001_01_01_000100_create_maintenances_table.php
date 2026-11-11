<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('maintenances', function (Blueprint $table) {
            $table->id();
            $table->string('maintenance_number')->unique();
            $table->foreignId('item_id')->constrained()->restrictOnDelete();
            $table->enum('type', ['preventive', 'corrective', 'calibration', 'inspection', 'repair']);
            $table->enum('status', ['scheduled', 'in_progress', 'completed', 'cancelled', 'overdue'])->default('scheduled');
            $table->date('scheduled_date');
            $table->date('completed_date')->nullable();
            $table->string('technician')->nullable();
            $table->decimal('cost', 12, 2)->default(0);
            $table->text('description')->nullable();
            $table->text('findings')->nullable();
            $table->text('recommendations')->nullable();
            $table->date('next_maintenance_date')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('maintenances');
    }
};
