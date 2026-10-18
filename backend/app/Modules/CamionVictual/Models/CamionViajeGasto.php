<?php

namespace App\Modules\CamionVictual\Models;

use App\Models\User;
use App\Modules\CamionVictual\Enums\TipoGastoViaje;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CamionViajeGasto extends Model
{
    protected $table = 'camion_viaje_gastos';

    protected $fillable = [
        'viaje_id',
        'tipo_gasto',
        'concepto',
        'cantidad',
        'precio_unitario',
        'monto_total',
        'comprobante',
        'registrado_por',
    ];

    protected $casts = [
        'tipo_gasto'      => TipoGastoViaje::class,
        'cantidad'        => 'decimal:2',
        'precio_unitario' => 'decimal:2',
        'monto_total'     => 'decimal:2',
    ];

    public function viaje(): BelongsTo
    {
        return $this->belongsTo(CamionViaje::class, 'viaje_id');
    }

    public function registradoPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'registrado_por');
    }
}
