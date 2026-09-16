<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Vehiculo extends Model
{
    use HasFactory;

    protected $fillable = [
        'ficha', 'placa', 'marca', 'modelo', 'año', 'tipo_energia', 
        'capacidad_carga', 'estado', 'created_by'
    ];

    public function creador()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function mantenimientos()
    {
        return $this->hasMany(VehiculoMantenimiento::class);
    }

    public function gastos()
    {
        return $this->hasMany(VehiculoGasto::class);
    }

    public function despachos()
    {
        return $this->hasMany(Despacho::class);
    }
}
