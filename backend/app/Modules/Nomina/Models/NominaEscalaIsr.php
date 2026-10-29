<?php

namespace App\Modules\Nomina\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class NominaEscalaIsr extends Model
{
    use HasFactory;

    protected $table = 'nomina_escalas_isr';

    protected $fillable = [
        'anio',
        'desde_mensual',
        'hasta_mensual',
        'tasa_porcentaje',
        'impuesto_base_mensual',
        'excedente_desde_mensual',
        'descripcion',
        'activo',
    ];

    protected $casts = [
        'anio'                    => 'integer',
        'desde_mensual'           => 'decimal:2',
        'hasta_mensual'           => 'decimal:2',
        'tasa_porcentaje'         => 'decimal:2',
        'impuesto_base_mensual'   => 'decimal:2',
        'excedente_desde_mensual' => 'decimal:2',
        'activo'                  => 'boolean',
    ];
}

