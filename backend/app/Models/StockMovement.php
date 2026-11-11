<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class StockMovement extends Model
{
    use HasFactory;

    protected $fillable = [
        'item_id', 'type', 'quantity', 'balance_after', 'user_id',
        'reference', 'reference_id', 'notes',
    ];

    public function item()
    {
        return $this->belongsTo(Item::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function getIsIncomingAttribute(): bool
    {
        return in_array($this->type, ['purchase', 'return_in']);
    }
}
