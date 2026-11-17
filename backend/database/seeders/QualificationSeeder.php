<?php

namespace Database\Seeders;

use App\Models\Qualification;
use Illuminate\Database\Seeder;

class QualificationSeeder extends Seeder
{
    public function run(): void
    {
        $qualifications = [
            ['code' => 'EIM-NCII', 'name' => 'Electrical Installation and Maintenance', 'nc_level' => 'NC II'],
            ['code' => 'DRM-NCII', 'name' => 'Dressmaking', 'nc_level' => 'NC II'],
            ['code' => 'HWM-NCII', 'name' => 'Hilot (Wellness Massage)', 'nc_level' => 'NC II'],
            ['code' => 'CSS-NCII', 'name' => 'Computer Systems Servicing', 'nc_level' => 'NC II'],
            ['code' => 'SMAW-NCII', 'name' => 'Shielded Metal Arc Welding', 'nc_level' => 'NC II'],
            ['code' => 'AUTO-NCII', 'name' => 'Automotive Servicing', 'nc_level' => 'NC II'],
            ['code' => 'COOK-NCII', 'name' => 'Cookery', 'nc_level' => 'NC II'],
            ['code' => 'BPP-NCII', 'name' => 'Bread and Pastry Production', 'nc_level' => 'NC II'],
            ['code' => 'FOS-NCII', 'name' => 'Food Processing', 'nc_level' => 'NC II'],
            ['code' => 'BKP-NCIII', 'name' => 'Bookkeeping', 'nc_level' => 'NC III'],
        ];

        foreach ($qualifications as $q) {
            Qualification::updateOrCreate(['code' => $q['code']], $q + ['is_active' => true]);
        }
    }
}
