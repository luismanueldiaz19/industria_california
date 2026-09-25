<?php

namespace App\Modules\Vehiculo\Models;

use App\Models\User;
use App\Modules\Vehiculo\Enums\EstadoMantenimiento;
use App\Modules\Vehiculo\Enums\TipoMantenimiento;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VehiculoMantenimiento extends Model
{
    protected $table = 'vehiculo_mantenimientos';

    protected $fillable = [
        'vehiculo_id',
        'tipo',
        'fecha_reporte',
        'descripcion',
        'costo',
        'estado',
        'evidencias',
        'reportado_por',
    ];

    protected $casts = [
        'tipo'          => TipoMantenimiento::class,
        'estado'        => EstadoMantenimiento::class,
        'fecha_reporte' => 'datetime',
        'costo'         => 'decimal:2',
        'evidencias'    => 'array',
    ];

    // ─── Relaciones ───────────────────────────────────────────────

    public function vehiculo(): BelongsTo
    {
        return $this->belongsTo(Vehiculo::class, 'vehiculo_id');
    }

    public function reportador(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reportado_por');
    }
}
