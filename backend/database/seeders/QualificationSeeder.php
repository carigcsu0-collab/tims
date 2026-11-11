<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Item;
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

        $ids = [];
        foreach ($qualifications as $q) {
            $ids[$q['code']] = Qualification::updateOrCreate(['code' => $q['code']], $q + ['is_active' => true])->id;
        }

        $cat = fn (string $code) => Category::where('code', $code)->value('id');

        // [sku, name, type, qualification, category code, qty, min stock, unit, unit cost, unit label]
        $items = [
            ['EIM-T-001', 'Combination Pliers', 'tool', 'EIM-NCII', 'HDT', 20, 5, 'pcs', 250],
            ['EIM-E-001', 'Digital Multimeter', 'equipment', 'EIM-NCII', 'EQP', 10, 2, 'pcs', 1800],
            ['EIM-C-001', 'THHN Wire 2.0mm (roll)', 'consumable', 'EIM-NCII', 'CNS', 15, 5, 'roll', 2400],
            ['DRM-E-001', 'Industrial Sewing Machine', 'equipment', 'DRM-NCII', 'EQP', 12, 2, 'unit', 18500],
            ['DRM-T-001', 'Tailor\'s Shears', 'tool', 'DRM-NCII', 'HDT', 15, 5, 'pcs', 650],
            ['DRM-C-001', 'Sewing Thread (cone)', 'consumable', 'DRM-NCII', 'CNS', 40, 15, 'cone', 85],
            ['HWM-E-001', 'Massage Bed', 'equipment', 'HWM-NCII', 'EQP', 8, 2, 'unit', 6500],
            ['HWM-C-001', 'Massage Oil (1L)', 'consumable', 'HWM-NCII', 'CNS', 12, 5, 'bottle', 320],
            ['HWM-C-002', 'Disposable Linens', 'consumable', 'HWM-NCII', 'CNS', 60, 20, 'pcs', 45],
        ];

        foreach ($items as [$sku, $name, $type, $qual, $catCode, $qty, $min, $unit, $cost]) {
            Item::updateOrCreate(['sku' => $sku], [
                'name' => $name,
                'type' => $type,
                'qualification_id' => $ids[$qual],
                'category_id' => $cat($catCode),
                'quantity' => $qty,
                'minimum_stock' => $min,
                'reorder_level' => $min * 2,
                'maximum_stock' => $qty * 3,
                'unit' => $unit,
                'unit_cost' => $cost,
                'total_value' => $qty * $cost,
                'condition' => 'working',
                'is_active' => true,
            ]);
        }
    }
}
