<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrdenProduccion extends Model
{
    use HasFactory;

    protected $fillable = [
        'pedido_id',
        'cliente_id',
        'vendedor_id',
        'estado',
        'fecha_estimada_entrega',
        'notas',
    ];

    protected $casts = [
        'fecha_estimada_entrega' => 'date',
    ];

    public function pedido()
    {
        return $this->belongsTo(Pedido::class);
    }

    public function cliente()
    {
        return $this->belongsTo(LedhouseCliente::class);
    }

    public function vendedor()
    {
        return $this->belongsTo(User::class, 'vendedor_id');
    }

    public function detalles()
    {
        return $this->hasMany(OrdenProduccionDetalle::class);
    }
}
