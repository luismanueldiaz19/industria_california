<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PdfToken extends Model
{
    protected $fillable = [
        'token',
        'tipo',
        'parametros',
        'user_id',
        'expires_at',
    ];

    protected $casts = [
        'parametros' => 'array',
        'expires_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function isValid(): bool
    {
        return $this->expires_at->isFuture();
    }
}
