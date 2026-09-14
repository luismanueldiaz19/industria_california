<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrdenProduccionDetalle extends Model
{
    use HasFactory;

    protected $fillable = [
        'orden_produccion_id',
        'producto_id',
        'pedido_detalle_id',
        'cantidad_faltante',
        'cantidad_producida',
        'estado',
    ];

    public function ordenProduccion()
    {
        return $this->belongsTo(OrdenProduccion::class);
    }

    public function producto()
    {
        return $this->belongsTo(InventarioProducto::class, 'producto_id');
    }

    public function pedidoDetalle()
    {
        return $this->belongsTo(PedidoDetalle::class);
    }
}
