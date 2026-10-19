<?php

namespace App\Modules\CamionVictual\Models;

use App\Models\Chofer;
use App\Models\User;
use App\Modules\CamionVictual\Enums\EstadoCamion;
use App\Modules\Pedido\Models\Pedido;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use App\Modules\CamionVictual\Enums\EstadoViaje;

class CamionVictual extends Model
{
    protected $table = 'camiones_victuales';

    protected $fillable = [
        'chofer_id',
        'vendedor_id',
        'vehiculo_id',
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
        'vehiculo_id'  => 'integer',
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

    public function vehiculo(): BelongsTo
    {
        return $this->belongsTo(\App\Modules\Vehiculo\Models\Vehiculo::class, 'vehiculo_id');
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

    public function viajes(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(CamionViaje::class, 'camion_victual_id')->orderBy('id', 'desc');
    }

    public function viajeActivo(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(CamionViaje::class, 'camion_victual_id')
            ->where('estado', EstadoViaje::EnRuta)
            ->latestOfMany();
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
