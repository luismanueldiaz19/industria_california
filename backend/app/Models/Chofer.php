<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Chofer extends Model
{
    use HasFactory;

    protected $table = 'choferes';

    protected $fillable = [
        'user_id', 'numero_licencia', 'tipo_licencia', 'vencimiento_licencia', 
        'contacto_emergencia', 'estado'
    ];

    protected $casts = [
        'vencimiento_licencia' => 'date',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function despachos()
    {
        return $this->hasMany(Despacho::class);
    }
}
