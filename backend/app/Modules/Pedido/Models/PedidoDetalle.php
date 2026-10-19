<?php

namespace App\Modules\Pedido\Models;

use App\Modules\Producto\Models\Producto;
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

    protected static function booted(): void
    {
        static::saving(function (PedidoDetalle $detalle) {
            $pedido = $detalle->pedido ?? Pedido::find($detalle->pedido_id);
            if ($pedido) {
                $estado = is_object($pedido->estado) ? $pedido->estado->value : (string) $pedido->estado;
                if ($estado === 'entregado') {
                    throw new \Exception('No se pueden modificar los artículos de un pedido ENTREGADO.');
                }
            }
        });

        static::deleting(function (PedidoDetalle $detalle) {
            $pedido = $detalle->pedido ?? Pedido::find($detalle->pedido_id);
            if ($pedido) {
                $estado = is_object($pedido->estado) ? $pedido->estado->value : (string) $pedido->estado;
                if ($estado === 'entregado') {
                    throw new \Exception('No se pueden eliminar los artículos de un pedido ENTREGADO.');
                }
            }
        });
    }

    public function pedido()
    {
        return $this->belongsTo(Pedido::class, 'pedido_id');
    }

    public function producto()
    {
        return $this->belongsTo(Producto::class, 'producto_id');
    }
}
