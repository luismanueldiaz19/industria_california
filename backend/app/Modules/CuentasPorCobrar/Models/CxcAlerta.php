<?php

namespace App\Modules\CuentasPorCobrar\Models;

use App\Models\User;
use App\Modules\CuentasPorCobrar\Enums\EstadoAlertaCxc;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CxcAlerta extends Model
{
    use HasFactory;

    protected $table = 'ledhouse_cxc_alertas';

    protected $fillable = [
        'ledhouse_cxc_id',
        'vendedor_id',
        'tipo',
        'monto_informado',
        'nota',
        'estado_alerta',
        'revisada_por',
        'fecha_revision',
    ];

    protected $casts = [
        'estado_alerta'   => EstadoAlertaCxc::class,
        'monto_informado' => 'decimal:2',
        'fecha_revision'  => 'datetime',
    ];

    public function cxc(): BelongsTo
    {
        return $this->belongsTo(CuentaPorCobrar::class, 'ledhouse_cxc_id');
    }

    public function vendedor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'vendedor_id');
    }

    public function revisador(): BelongsTo
    {
        return $this->belongsTo(User::class, 'revisada_por');
    }

    public function evidencias(): HasMany
    {
        return $this->hasMany(CxcEvidencia::class, 'alerta_id');
    }
}
