<?php

namespace App\Modules\CuentasPorCobrar\Models;

use App\Models\User;
use App\Modules\Cliente\Models\Cliente;
use App\Modules\CuentasPorCobrar\Enums\EstadoCuarentenaCxc;
use App\Modules\CuentasPorCobrar\Enums\MotivoCuarentenaCxc;
use App\Modules\CuentasPorCobrar\Enums\TipoNotaCxc;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CxcCuarentena extends Model
{
    protected $table = 'ledhouse_cxc_cuarentenas';

    protected $fillable = [
        'cxc_id_original',
        'documento',
        'cliente_id',
        'cliente_nombre',
        'vendedor_id',
        'vendedor_nombre',
        'fecha_factura',
        'fecha_vencimiento',
        'monto_factura',
        'monto_pagado',
        'monto_pendiente',
        'tipo_nota',
        'monto_nota',
        'motivo',
        'justificacion',
        'estado',
        'numero_nota_externa',
        'nota_resolucion',
        'fecha_resolucion',
        'snapshot',
        'enviado_por',
        'resuelto_por',
    ];

    protected $casts = [
        'tipo_nota'         => TipoNotaCxc::class,
        'motivo'            => MotivoCuarentenaCxc::class,
        'estado'            => EstadoCuarentenaCxc::class,
        'monto_factura'     => 'decimal:2',
        'monto_pagado'      => 'decimal:2',
        'monto_pendiente'   => 'decimal:2',
        'monto_nota'        => 'decimal:2',
        'fecha_factura'     => 'date:Y-m-d',
        'fecha_vencimiento' => 'date:Y-m-d',
        'fecha_resolucion'  => 'datetime',
        'snapshot'          => 'array',
    ];

    protected $appends = [
        'nombre_enviado_por',
        'nombre_resuelto_por',
    ];

    public function getNombreEnviadoPorAttribute(): ?string
    {
        return $this->enviadoPor?->name;
    }

    public function getNombreResueltoPorAttribute(): ?string
    {
        return $this->resueltoPor?->name;
    }

    public function cliente(): BelongsTo
    {
        return $this->belongsTo(Cliente::class, 'cliente_id');
    }

    public function vendedor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'vendedor_id');
    }

    public function enviadoPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'enviado_por');
    }

    public function resueltoPor(): BelongsTo
    {
        return $this->belongsTo(User::class, 'resuelto_por');
    }

    public function estaPendiente(): bool
    {
        return $this->estado === EstadoCuarentenaCxc::Pendiente;
    }
}
