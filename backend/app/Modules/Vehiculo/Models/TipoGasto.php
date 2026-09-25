<?php

namespace App\Modules\Vehiculo\Models;

use Illuminate\Database\Eloquent\Model;

class TipoGasto extends Model
{
    protected $table = 'tipo_gastos';
    protected $fillable = ['nombre'];
}
