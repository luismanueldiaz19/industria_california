<?php

namespace App\Modules\CamionVictual\Models;

use App\Modules\CamionVictual\Enums\EstadoEntrega;
use App\Modules\Pedido\Models\Pedido;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CamionViajePedido extends Model
{
    protected $table = 'camion_viaje_pedidos';

    protected $fillable = [
        'viaje_id',
        'pedido_id',
        'orden_viaje',
        'estado_entrega',
        'fecha_entregado',
        'comentario_entrega',
        'total_pedido',
    ];

    protected $casts = [
        'estado_entrega'  => EstadoEntrega::class,
        'fecha_entregado' => 'datetime',
        'total_pedido'    => 'decimal:2',
        'orden_viaje'     => 'integer',
    ];

    public function viaje(): BelongsTo
    {
        return $this->belongsTo(CamionViaje::class, 'viaje_id');
    }

    public function pedido(): BelongsTo
    {
        return $this->belongsTo(Pedido::class, 'pedido_id');
    }
}
