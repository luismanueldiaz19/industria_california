<?php

namespace App\Modules\Empleado\Models;

use App\Models\User;
use App\Modules\Empleado\Enums\EstadoEmpleado;
use App\Modules\Empleado\Enums\TipoPago;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Empleado extends Model
{
    use SoftDeletes;

    protected $table = 'empleados';

    protected $fillable = [
        'cedula',
        'nombres',
        'apellidos',
        'ocupacion',
        'departamento',
        'telefono',
        'email',
        'direccion',
        'salario_mensual',
        'salario_quincenal',
        'salario_hora',
        'aplica_afp',
        'aplica_ars',
        'aplica_isr',
        'tipo_pago',
        'banco',
        'numero_cuenta',
        'estado',
        'fecha_ingreso',
        'fecha_salida',
        'created_by',
    ];

    protected $casts = [
        'salario_mensual'   => 'decimal:2',
        'salario_quincenal' => 'decimal:2',
        'salario_hora'      => 'decimal:4',
        'aplica_afp'        => 'boolean',
        'aplica_ars'        => 'boolean',
        'aplica_isr'        => 'boolean',
        'estado'            => EstadoEmpleado::class,
        'tipo_pago'         => TipoPago::class,
        'fecha_ingreso'     => 'date',
        'fecha_salida'      => 'date',
    ];

    // Accesor: Nombre Completo
    public function getNombreCompletoAttribute(): string
    {
        return trim("{$this->nombres} {$this->apellidos}");
    }

    // Relaciones
    public function creador(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    // Helpers
    public function estaActivo(): bool
    {
        return $this->estado === EstadoEmpleado::Activo;
    }
}

