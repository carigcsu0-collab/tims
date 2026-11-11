<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('qualifications', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('code')->unique();
            $table->string('nc_level')->nullable();
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::table('items', function (Blueprint $table) {
            $table->foreignId('qualification_id')->nullable()->after('category_id')
                ->constrained('qualifications')->nullOnDelete();
            $table->enum('condition', ['working', 'needs_repair', 'condemned', 'missing'])
                ->default('working')->after('status');
            $table->index(['qualification_id', 'type']);
        });
    }

    public function down(): void
    {
        Schema::table('items', function (Blueprint $table) {
            $table->dropIndex(['qualification_id', 'type']);
            $table->dropConstrainedForeignId('qualification_id');
            $table->dropColumn('condition');
        });

        Schema::dropIfExists('qualifications');
    }
};
