<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class VehiculoGasto extends Model
{
    use HasFactory;

    protected $fillable = [
        'vehiculo_id', 'fecha_gasto', 'concepto', 'cantidad', 
        'unidad_medida', 'precio_unitario', 'monto_total', 
        'comprobantes', 'registrado_por'
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

    public function registrador()
    {
        return $this->belongsTo(User::class, 'registrado_por');
    }
}
