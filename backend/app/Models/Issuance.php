<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Issuance extends Model
{
    use HasFactory;

    protected $fillable = [
        'issuance_number', 'issued_to', 'issued_by', 'issue_date', 'purpose', 'notes',
    ];

    protected function casts(): array
    {
        return [
            'issue_date' => 'date',
        ];
    }

    public function issuedTo()
    {
        return $this->belongsTo(User::class, 'issued_to');
    }

    public function issuedBy()
    {
        return $this->belongsTo(User::class, 'issued_by');
    }

    public function items()
    {
        return $this->hasMany(IssuanceItem::class);
    }
}
