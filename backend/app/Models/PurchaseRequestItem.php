<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class PurchaseRequestItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'purchase_request_id', 'item_id', 'quantity', 'unit_cost', 'unit', 'notes',
    ];

    protected function casts(): array
    {
        return [
            'unit_cost' => 'decimal:2',
        ];
    }

    public function purchaseRequest()
    {
        return $this->belongsTo(PurchaseRequest::class);
    }

    public function item()
    {
        return $this->belongsTo(Item::class);
    }

    public function getTotalCostAttribute(): float
    {
        return $this->quantity * (float) $this->unit_cost;
    }
}
