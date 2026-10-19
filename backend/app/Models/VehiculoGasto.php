<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class VehiculoGasto extends Model
{
    use HasFactory;

    protected $fillable = [
        'vehiculo_id', 'viaje_id', 'tipo_gasto', 'fecha_gasto', 'concepto', 'cantidad', 
        'unidad_medida', 'precio_unitario', 'monto_total', 
        'comprobante', 'comprobantes', 'registrado_por'
    ];

    protected $casts = [
        'fecha_gasto' => 'date',
        'cantidad' => 'decimal:2',
        'precio_unitario' => 'decimal:2',
        'monto_total' => 'decimal:2',
        'comprobantes' => 'array',
    ];

    public function vehiculo()
    {
        return $this->belongsTo(Vehiculo::class);
    }

    public function viaje()
    {
        return $this->belongsTo(\App\Modules\CamionVictual\Models\CamionViaje::class, 'viaje_id');
    }

    public function registrador()
    {
        return $this->belongsTo(User::class, 'registrado_por');
    }

    // Mutators (Uppercase siempre)
    public function setConceptoAttribute($value): void
    {
        $this->attributes['concepto'] = $value ? mb_strtoupper(trim($value), 'UTF-8') : $value;
    }

    public function setTipoGastoAttribute($value): void
    {
        $this->attributes['tipo_gasto'] = $value ? mb_strtoupper(trim($value), 'UTF-8') : $value;
    }

    public function setUnidadMedidaAttribute($value): void
    {
        $this->attributes['unidad_medida'] = $value ? mb_strtoupper(trim($value), 'UTF-8') : $value;
    }
}
