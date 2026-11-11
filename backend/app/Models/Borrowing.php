<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Borrowing extends Model
{
    use HasFactory;

    protected $fillable = [
        'borrow_number', 'item_id', 'borrower_id', 'status', 'borrow_date',
        'expected_return_date', 'actual_return_date', 'quantity', 'purpose',
        'approved_by', 'condition_out', 'condition_in', 'notes', 'return_id',
    ];

    protected function casts(): array
    {
        return [
            'borrow_date' => 'date',
            'expected_return_date' => 'date',
            'actual_return_date' => 'date',
        ];
    }

    public function item()
    {
        return $this->belongsTo(Item::class);
    }

    public function borrower()
    {
        return $this->belongsTo(User::class, 'borrower_id');
    }

    public function approvedBy()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function getIsOverdueAttribute(): bool
    {
        if ($this->status !== 'borrowed') return false;
        if (!$this->expected_return_date) return false;
        return now()->isAfter($this->expected_return_date);
    }
}
