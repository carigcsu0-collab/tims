<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Maintenance extends Model
{
    use HasFactory;

    protected $fillable = [
        'maintenance_number', 'item_id', 'type', 'status', 'scheduled_date',
        'completed_date', 'technician', 'cost', 'description', 'findings',
        'recommendations', 'next_maintenance_date',
    ];

    protected function casts(): array
    {
        return [
            'scheduled_date' => 'date',
            'completed_date' => 'date',
            'next_maintenance_date' => 'date',
            'cost' => 'decimal:2',
        ];
    }

    public function item()
    {
        return $this->belongsTo(Item::class);
    }
}
