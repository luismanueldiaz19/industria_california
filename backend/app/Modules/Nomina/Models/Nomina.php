<?php

namespace App\Modules\Nomina\Models;

use App\Models\User;
use App\Modules\Nomina\Enums\EstadoNomina;
use App\Modules\Nomina\Enums\TipoPeriodoNomina;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Nomina extends Model
{
    use SoftDeletes;

    protected $table = 'nominas';

    protected $fillable = [
        'codigo',
        'titulo',
        'tipo_periodo',
        'fecha_inicio',
        'fecha_fin',
        'fecha_pago',
        'estado',
        'total_ingresos',
        'total_deducciones',
        'total_neto',
        'realizado_por',
        'aprobado_por',
        'notas',
    ];

    protected $casts = [
        'estado'            => EstadoNomina::class,
        'tipo_periodo'      => TipoPeriodoNomina::class,
        'fecha_inicio'      => 'date:Y-m-d',
        'fecha_fin'         => 'date:Y-m-d',
        'fecha_pago'        => 'date:Y-m-d',
        'total_ingresos'    => 'decimal:2',
        'total_deducciones' => 'decimal:2',
        'total_neto'        => 'decimal:2',
    ];

    public function detalles(): HasMany
    {
        return $this->hasMany(NominaDetalle::class, 'nomina_id');
    }

    public function creador(): BelongsTo
    {
        return $this->belongsTo(User::class, 'realizado_por');
    }

    public function aprobador(): BelongsTo
    {
        return $this->belongsTo(User::class, 'aprobado_por');
    }
}

