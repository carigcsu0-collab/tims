<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class InventoryAuditItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'inventory_audit_id', 'item_id', 'expected_quantity',
        'actual_quantity', 'discrepancy', 'notes',
    ];

    public function inventoryAudit()
    {
        return $this->belongsTo(InventoryAudit::class);
    }

    public function item()
    {
        return $this->belongsTo(Item::class);
    }
}
