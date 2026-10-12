<?php

namespace App\Modules\CuentasPorCobrar\Models;

use App\Models\User;
use App\Modules\Cliente\Models\Cliente;
use App\Modules\CuentasPorCobrar\Enums\EstadoCxc;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CuentaPorCobrar extends Model
{
    use HasFactory;

    protected $table = 'ledhouse_cxcs';

    protected $fillable = [
        'documento',
        'cliente_id',
        'vendedor_id',
        'monto_factura',
        'monto_pagado',
        'monto_pendiente',
        'fecha_factura',
        'fecha_vencimiento',
        'estado',
    ];

    protected $casts = [
        'estado'           => EstadoCxc::class,
        'monto_factura'    => 'decimal:2',
        'monto_pagado'     => 'decimal:2',
        'monto_pendiente'  => 'decimal:2',
        'fecha_factura'    => 'date',
        'fecha_vencimiento'=> 'date',
    ];

    public function cliente(): BelongsTo
    {
        return $this->belongsTo(Cliente::class, 'cliente_id');
    }

    public function vendedor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'vendedor_id');
    }

    public function alertas(): HasMany
    {
        return $this->hasMany(CxcAlerta::class, 'ledhouse_cxc_id');
    }

    public function evidencias(): HasMany
    {
        return $this->hasMany(CxcEvidencia::class, 'ledhouse_cxc_id');
    }

    public function soportes(): HasMany
    {
        return $this->hasMany(CxcSoporte::class, 'ledhouse_cxc_id');
    }

    public function estaVencido(): bool
    {
        if ($this->estado === EstadoCxc::Pagado || (float)$this->monto_pendiente <= 0) {
            return false;
        }

        return $this->fecha_vencimiento && $this->fecha_vencimiento->isPast();
    }
}
