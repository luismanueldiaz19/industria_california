<?php

namespace App\Modules\CamionVictual\Models;

use App\Models\Chofer;
use App\Models\User;
use App\Modules\CamionVictual\Enums\EstadoCamion;
use App\Modules\Pedido\Models\Pedido;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class CamionVictual extends Model
{
    protected $table = 'camiones_victuales';

    protected $fillable = [
        'chofer_id',
        'vendedor_id',
        'nombre',
        'slot_numero',
        'estado',
        'monto_total',
        'minimo_salida',
        'fecha_cierre',
        'cerrado_por',
        'notas',
    ];

    protected $casts = [
        'estado'       => EstadoCamion::class,
        'monto_total'  => 'decimal:2',
        'minimo_salida'=> 'decimal:2',
        'fecha_cierre' => 'datetime',
        'slot_numero'  => 'integer',
    ];

    // ─── Relaciones ───────────────────────────────────────────────

    public function chofer(): BelongsTo
    {
        return $this->belongsTo(Chofer::class, 'chofer_id');
    }

    public function vendedor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'vendedor_id');
    }

    public function cerradoPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'cerrado_por');
    }

    /**
     * Pedidos asignados a este camión, ordenados por el orden definido por el vendedor.
     */
    public function pedidos(): BelongsToMany
    {
        return $this->belongsToMany(Pedido::class, 'camion_victual_pedido')
            ->withPivot(['orden_viaje', 'estado_entrega', 'comentario_entrega', 'fecha_entregado'])
            ->withTimestamps()
            ->orderByPivot('orden_viaje', 'asc');
    }

    // ─── Helpers ─────────────────────────────────────────────────

    public function estaAbierto(): bool
    {
        return in_array($this->estado, [EstadoCamion::Vacio, EstadoCamion::Armando, EstadoCamion::Listo]);
    }

    public function puedeModificarPedidos(): bool
    {
        return in_array($this->estado, [EstadoCamion::Armando, EstadoCamion::Vacio]);
    }
}
