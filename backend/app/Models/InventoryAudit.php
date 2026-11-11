<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class InventoryAudit extends Model
{
    use HasFactory;

    protected $fillable = [
        'audit_number', 'auditor_id', 'audit_date', 'status', 'notes',
    ];

    protected function casts(): array
    {
        return [
            'audit_date' => 'date',
        ];
    }

    public function auditor()
    {
        return $this->belongsTo(User::class, 'auditor_id');
    }

    public function items()
    {
        return $this->hasMany(InventoryAuditItem::class);
    }
}
