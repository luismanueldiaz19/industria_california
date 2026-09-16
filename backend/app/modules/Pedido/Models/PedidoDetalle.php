<?php

namespace App\Modules\Pedido\Models;

use App\Models\InventarioProducto;
use App\Modules\Pedido\Models\Pedido;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PedidoDetalle extends Model
{
    use HasFactory;

    protected $fillable = [
        'pedido_id',
        'producto_id',
        'cantidad',
        'cantidad_en_produccion',
        'precio_unitario',
        'subtotal',
        'observacion',
    ];

    protected $casts = [
        'cantidad' => 'decimal:3',
        'cantidad_en_produccion' => 'decimal:3',
        'precio_unitario' => 'decimal:2',
        'subtotal' => 'decimal:2',
    ];

    public function pedido()
    {
        return $this->belongsTo(Pedido::class, 'pedido_id');
    }

    public function producto()
    {
        return $this->belongsTo(InventarioProducto::class, 'producto_id');
    }
}
