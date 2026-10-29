<?php

namespace App\Modules\Nomina\Models;

use App\Modules\Nomina\Enums\CategoriaConceptoNomina;
use App\Modules\Nomina\Enums\TipoConceptoNomina;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class NominaConcepto extends Model
{
    protected $table = 'nomina_conceptos';

    protected $fillable = [
        'codigo',
        'nombre',
        'tipo',
        'categoria',
        'es_automatico',
        'es_porcentual',
        'porcentaje',
        'es_cotizable_tss',
        'es_gravable_isr',
        'activo',
    ];

    protected $casts = [
        'tipo'             => TipoConceptoNomina::class,
        'categoria'        => CategoriaConceptoNomina::class,
        'es_automatico'    => 'boolean',
        'es_porcentual'    => 'boolean',
        'porcentaje'       => 'decimal:4',
        'es_cotizable_tss' => 'boolean',
        'es_gravable_isr'  => 'boolean',
        'activo'           => 'boolean',
    ];

    public function detalleConceptos(): HasMany
    {
        return $this->hasMany(NominaDetalleConcepto::class, 'concepto_id');
    }

    public function recurrentes(): HasMany
    {
        return $this->hasMany(NominaEmpleadoRecurrente::class, 'concepto_id');
    }
}

