<?php

namespace App\Modules\Nomina\Models;

use App\Modules\Nomina\Enums\TipoConceptoNomina;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NominaDetalleConcepto extends Model
{
    protected $table = 'nomina_detalle_conceptos';

    protected $fillable = [
        'nomina_detalle_id',
        'concepto_id',
        'tipo',
        'monto',
        'cantidad',
        'valor_unitario',
        'referencia_cuota',
        'notas',
    ];

    protected $casts = [
        'tipo'           => TipoConceptoNomina::class,
        'monto'          => 'decimal:2',
        'cantidad'       => 'decimal:2',
        'valor_unitario' => 'decimal:2',
    ];

    public function detalle(): BelongsTo
    {
        return $this->belongsTo(NominaDetalle::class, 'nomina_detalle_id');
    }

    public function concepto(): BelongsTo
    {
        return $this->belongsTo(NominaConcepto::class, 'concepto_id');
    }
}

