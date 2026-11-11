<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Supplier extends Model
{
    use HasFactory;

    protected $fillable = [
        'name', 'code', 'contact_person', 'email', 'phone', 'address',
        'city', 'province', 'zip_code', 'tin', 'website', 'notes',
        'is_active', 'rating', 'total_purchases',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'rating' => 'decimal:1',
        ];
    }

    public function items()
    {
        return $this->hasMany(Item::class);
    }

    public function purchaseOrders()
    {
        return $this->hasMany(PurchaseOrder::class);
    }
}
