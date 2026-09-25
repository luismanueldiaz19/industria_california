<?php

namespace App\Modules\Vehiculo\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VehiculoGasto extends Model
{
    protected $table = 'vehiculo_gastos';

    protected $fillable = [
        'vehiculo_id',
        'tipo_gasto',
        'fecha_gasto',
        'concepto',
        'cantidad',
        'unidad_medida',
        'precio_unitario',
        'monto_total',
        'comprobantes',
        'registrado_por',
    ];

    protected $casts = [
        'fecha_gasto'     => 'date',
        'cantidad'        => 'decimal:2',
        'precio_unitario' => 'decimal:2',
        'monto_total'     => 'decimal:2',
        'comprobantes'    => 'array',
    ];

    // ─── Relaciones ───────────────────────────────────────────────

    public function vehiculo(): BelongsTo
    {
        return $this->belongsTo(Vehiculo::class, 'vehiculo_id');
    }

    public function registrador(): BelongsTo
    {
        return $this->belongsTo(User::class, 'registrado_por');
    }
}
