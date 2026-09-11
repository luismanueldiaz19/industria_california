<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Ruta extends Model
{
    use HasFactory;

    protected $fillable = [
        'nombre',
        'chofer',
        'ficha_camion',
        'created_by',
    ];

    public function creador()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
