<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LedhouseCxcEvidencia extends Model
{
    protected $fillable = [
        'ledhouse_cxc_id',
        'alerta_id',
        'subido_por',
        'nombre_archivo',
        'ruta_archivo',
        'tipo_archivo',
    ];

    public function cxc()
    {
        return $this->belongsTo(LedhouseCxc::class, 'ledhouse_cxc_id');
    }

    public function alerta()
    {
        return $this->belongsTo(LedhouseCxcAlerta::class, 'alerta_id');
    }

    public function subidoPor()
    {
        return $this->belongsTo(\App\Models\User::class, 'subido_por');
    }
}
