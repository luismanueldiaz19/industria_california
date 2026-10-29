<?php

namespace App\Modules\Nomina\Models;

use App\Modules\Empleado\Models\Empleado;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class NominaDetalle extends Model
{
    protected $table = 'nomina_detalles';

    protected $fillable = [
        'nomina_id',
        'empleado_id',
        'salario_mensual',
        'salario_periodo',
        'salario_hora',
        'dias_trabajados',
        'horas_trabajadas',
        'horas_no_laboradas',
        'horas_extras',
        'total_ingresos',
        'total_deducciones',
        'neto_pagar',
        'comentarios',
    ];

    protected $casts = [
        'salario_mensual'    => 'decimal:2',
        'salario_periodo'    => 'decimal:2',
        'salario_hora'       => 'decimal:4',
        'dias_trabajados'    => 'decimal:2',
        'horas_trabajadas'   => 'decimal:2',
        'horas_no_laboradas' => 'decimal:2',
        'horas_extras'       => 'decimal:2',
        'total_ingresos'     => 'decimal:2',
        'total_deducciones'  => 'decimal:2',
        'neto_pagar'         => 'decimal:2',
    ];

    public function nomina(): BelongsTo
    {
        return $this->belongsTo(Nomina::class, 'nomina_id');
    }

    public function empleado(): BelongsTo
    {
        return $this->belongsTo(Empleado::class, 'empleado_id');
    }

    public function conceptos(): HasMany
    {
        return $this->hasMany(NominaDetalleConcepto::class, 'nomina_detalle_id');
    }
}

