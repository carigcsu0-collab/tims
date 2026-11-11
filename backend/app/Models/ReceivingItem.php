<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class ReceivingItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'receiving_id', 'item_id', 'quantity_received', 'unit_cost', 'notes',
    ];

    protected function casts(): array
    {
        return [
            'unit_cost' => 'decimal:2',
        ];
    }

    public function receiving()
    {
        return $this->belongsTo(Receiving::class);
    }

    public function item()
    {
        return $this->belongsTo(Item::class);
    }
}
