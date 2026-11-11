<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class IssuanceItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'issuance_id', 'item_id', 'quantity', 'notes',
    ];

    public function issuance()
    {
        return $this->belongsTo(Issuance::class);
    }

    public function item()
    {
        return $this->belongsTo(Item::class);
    }
}
