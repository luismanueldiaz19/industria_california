<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class LedhouseCliente extends Model
{
    use HasFactory;

    protected $fillable = [
        'id_cliente_externo',
        'nombre',
        'whatsapp',
        'direccion',
        'tipo_documento',
        'documento',
        'limite_credito',
        'dias_credito',
        'latitud',
        'longitud'
    ];

    public function cxcs()
    {
        return $this->hasMany(LedhouseCxc::class, 'cliente_id');
    }
}
