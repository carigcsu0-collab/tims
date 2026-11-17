<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Item extends Model
{
    use HasFactory;

    protected $fillable = [
        'name', 'sku', 'barcode', 'type', 'status', 'condition', 'unit', 'category_id', 'qualification_id',
        'description', 'brand', 'model', 'serial_number', 'quantity',
        'minimum_stock', 'maximum_stock', 'reorder_level', 'unit_cost',
        'total_value', 'location', 'image_url', 'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'quantity' => 'integer',
            'minimum_stock' => 'integer',
            'maximum_stock' => 'integer',
            'reorder_level' => 'integer',
            'unit_cost' => 'decimal:2',
            'total_value' => 'decimal:2',
        ];
    }

    protected static function booted(): void
    {
        // Keep the stock-level status in sync with quantity; manual states (damaged etc.) are preserved.
        static::saving(function (Item $item) {
            if (in_array($item->status, ['in_stock', 'low_stock', 'out_of_stock', null], true)) {
                $item->status = (int) $item->quantity <= 0
                    ? 'out_of_stock'
                    : ((int) $item->quantity <= (int) $item->minimum_stock ? 'low_stock' : 'in_stock');
            }
        });
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function qualification()
    {
        return $this->belongsTo(Qualification::class);
    }

    public function borrowings()
    {
        return $this->hasMany(Borrowing::class);
    }

    public function maintenances()
    {
        return $this->hasMany(Maintenance::class);
    }

    public function stockMovements()
    {
        return $this->hasMany(StockMovement::class);
    }

    public function getIsLowStockAttribute(): bool
    {
        return $this->quantity <= $this->minimum_stock && $this->quantity > 0;
    }

    public function getIsOutOfStockAttribute(): bool
    {
        return $this->quantity === 0;
    }

    public function getNeedsReorderAttribute(): bool
    {
        return $this->quantity <= $this->reorder_level;
    }
}
