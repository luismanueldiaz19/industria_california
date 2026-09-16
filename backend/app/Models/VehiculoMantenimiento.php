<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class VehiculoMantenimiento extends Model
{
    use HasFactory;

    protected $fillable = [
        'vehiculo_id', 'tipo', 'fecha_reporte', 'descripcion', 
        'costo', 'estado', 'evidencias', 'reportado_por'
    ];

    protected $casts = [
        'fecha_reporte' => 'datetime',
        'costo' => 'decimal:2',
        'evidencias' => 'array',
    ];

    public function vehiculo()
    {
        return $this->belongsTo(Vehiculo::class);
    }

    public function reportador()
    {
        return $this->belongsTo(User::class, 'reportado_por');
    }
}
