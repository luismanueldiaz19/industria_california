<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Pedido extends Model
{
    use HasFactory;

    protected $fillable = [
        'cliente_id',
        'ruta_id',
        'vendedor_id',
        'facturador_id',
        'estado',
        'comentario',
        'total',
        'latitud',
        'longitud'
    ];

    protected $casts = [
        'total' => 'decimal:2',
    ];

    public function cliente()
    {
        return $this->belongsTo(LedhouseCliente::class, 'cliente_id');
    }

    public function ruta()
    {
        return $this->belongsTo(Ruta::class, 'ruta_id');
    }

    public function vendedor()
    {
        return $this->belongsTo(User::class, 'vendedor_id');
    }

    public function facturador()
    {
        return $this->belongsTo(User::class, 'facturador_id');
    }

    public function detalles()
    {
        return $this->hasMany(PedidoDetalle::class, 'pedido_id');
    }
}
