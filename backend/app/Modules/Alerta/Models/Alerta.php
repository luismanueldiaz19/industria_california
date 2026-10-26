<?php

namespace App\Modules\Alerta\Models;

use App\Models\User;
use App\Models\LedhouseCxc;
use App\Modules\Alerta\Enums\EstadoAlerta;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Alerta extends Model
{
    use HasFactory;

    protected $table = 'ledhouse_cxc_alertas';

    protected $fillable = [
        'ledhouse_cxc_id',
        'vendedor_id',
        'grupo_pago_id',
        'tipo',
        'monto_informado',
        'nota',
        'estado_alerta',
        'revisada_por',
        'fecha_revision',
    ];

    protected $casts = [
        'estado_alerta'   => EstadoAlerta::class,
        'monto_informado' => 'decimal:2',
        'fecha_revision'  => 'datetime',
        'created_at'      => 'datetime',
        'updated_at'      => 'datetime',
    ];

    public function cxc(): BelongsTo
    {
        return $this->belongsTo(LedhouseCxc::class, 'ledhouse_cxc_id');
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
        return $this->hasMany(AlertaEvidencia::class, 'alerta_id');
    }

    /**
     * Todas las alertas que pertenecen al mismo pago agrupado (incluida esta).
     * Si la alerta no pertenece a un grupo, la relación devuelve una colección vacía.
     */
    public function grupoAlertas(): HasMany
    {
        return $this->hasMany(Alerta::class, 'grupo_pago_id', 'grupo_pago_id');
    }

    public function esPagoAgrupado(): bool
    {
        return !empty($this->grupo_pago_id);
    }

    public function isPendiente(): bool
    {
        return $this->estado_alerta === EstadoAlerta::Pendiente;
    }

    public function isProcesada(): bool
    {
        return $this->estado_alerta === EstadoAlerta::Procesada;
    }

    public function isRevisada(): bool
    {
        return $this->estado_alerta === EstadoAlerta::Revisada;
    }
}
