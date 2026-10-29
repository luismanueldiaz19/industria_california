<?php

namespace App\Modules\Nomina\Models;

use App\Modules\Empleado\Models\Empleado;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NominaEmpleadoRecurrente extends Model
{
    protected $table = 'nomina_empleado_recurrentes';

    protected $fillable = [
        'empleado_id',
        'concepto_id',
        'descripcion',
        'monto_total',
        'monto_cuota',
        'cuotas_totales',
        'cuotas_pagadas',
        'saldo_restante',
        'activo',
    ];

    protected $casts = [
        'monto_total'    => 'decimal:2',
        'monto_cuota'    => 'decimal:2',
        'saldo_restante' => 'decimal:2',
        'cuotas_totales' => 'integer',
        'cuotas_pagadas' => 'integer',
        'activo'         => 'boolean',
    ];

    public function empleado(): BelongsTo
    {
        return $this->belongsTo(Empleado::class, 'empleado_id');
    }

    public function concepto(): BelongsTo
    {
        return $this->belongsTo(NominaConcepto::class, 'concepto_id');
    }
}

