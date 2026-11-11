<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class ReturnModel extends Model
{
    use HasFactory;

    protected $table = 'returns';

    protected $fillable = [
        'return_number', 'borrowing_id', 'item_id', 'returned_by',
        'return_date', 'quantity', 'condition', 'notes',
    ];

    protected function casts(): array
    {
        return [
            'return_date' => 'date',
        ];
    }

    public function borrowing()
    {
        return $this->belongsTo(Borrowing::class);
    }

    public function item()
    {
        return $this->belongsTo(Item::class);
    }

    public function returnedBy()
    {
        return $this->belongsTo(User::class, 'returned_by');
    }
}
