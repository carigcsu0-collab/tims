<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name', 'email', 'password', 'role', 'permissions', 'avatar_url',
        'phone', 'position', 'department', 'center_name', 'center_id',
        'is_active', 'last_login_at',
    ];

    protected $hidden = [
        'password', 'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'last_login_at' => 'datetime',
            'permissions' => 'array',
            'password' => 'hashed',
        ];
    }

    public function borrowings()
    {
        return $this->hasMany(Borrowing::class, 'borrower_id');
    }

    public function approvedBorrowings()
    {
        return $this->hasMany(Borrowing::class, 'approved_by');
    }

    public function purchaseRequests()
    {
        return $this->hasMany(PurchaseRequest::class, 'requested_by');
    }

    public function activityLogs()
    {
        return $this->hasMany(ActivityLog::class);
    }

    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }
}
