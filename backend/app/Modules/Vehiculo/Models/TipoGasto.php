<?php

namespace App\Modules\Vehiculo\Models;

use Illuminate\Database\Eloquent\Model;

class TipoGasto extends Model
{
    protected $table = 'tipo_gastos';
    protected $fillable = ['nombre'];

    public function setNombreAttribute($value): void
    {
        $this->attributes['nombre'] = $value ? mb_strtoupper(trim($value), 'UTF-8') : $value;
    }
}

