<?php

namespace App\Modules\Vehiculo\Models;

use App\Models\User;
use App\Modules\Vehiculo\Enums\EstadoVehiculo;
use App\Modules\Vehiculo\Enums\TipoEnergia;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Vehiculo extends Model
{
    protected $table = 'vehiculos';

    protected $fillable = [
        'ficha',
        'placa',
        'marca',
        'modelo',
        'anio',
        'tipo_energia',
        'capacidad_carga',
        'estado',
        'created_by',
    ];

    protected $casts = [
        'estado'          => EstadoVehiculo::class,
        'tipo_energia'    => TipoEnergia::class,
        'capacidad_carga' => 'decimal:2',
        'anio'            => 'integer',
    ];

    /**
     * Mapea el campo PHP "anio" al campo real de la BD "año".
     * Se usa esta convencion para evitar problemas con caracteres UTF-8 en nombre de columna.
     */
    public function getAnioAttribute(): ?int
    {
        return $this->attributes['año'] ?? null;
    }

    public function setAnioAttribute(?int $value): void
    {
        $this->attributes['año'] = $value;
    }

    // --- Relaciones ---

    public function creador(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function mantenimientos(): HasMany
    {
        return $this->hasMany(VehiculoMantenimiento::class, 'vehiculo_id');
    }

    public function gastos(): HasMany
    {
        return $this->hasMany(VehiculoGasto::class, 'vehiculo_id');
    }

    // --- Helpers ---

    public function estaDisponible(): bool
    {
        return $this->estado === EstadoVehiculo::Disponible;
    }

    public function estaEnMantenimiento(): bool
    {
        return $this->estado === EstadoVehiculo::EnMantenimiento;
    }
}