<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Category;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        if (env('ADMIN_EMAIL') && env('ADMIN_PASSWORD') && ! User::where('email', env('ADMIN_EMAIL'))->exists()) {
            User::create([
                'name' => env('ADMIN_NAME', 'System Administrator'),
                'email' => env('ADMIN_EMAIL'),
                'password' => env('ADMIN_PASSWORD'),
                'role' => 'admin',
                'is_active' => true,
            ]);
        }

        Category::firstOrCreate(['code' => 'TLS'], ['name' => 'Tools', 'is_active' => true]);
        Category::firstOrCreate(['code' => 'EQP'], ['name' => 'Equipment', 'is_active' => true]);
        Category::firstOrCreate(['code' => 'CNS'], ['name' => 'Consumables', 'is_active' => true]);
        Category::firstOrCreate(['code' => 'MAT'], ['name' => 'Materials', 'is_active' => true]);

        $this->call(QualificationSeeder::class);
    }
}
