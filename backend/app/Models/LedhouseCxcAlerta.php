<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LedhouseCxcAlerta extends Model
{
    protected $fillable = [
        'ledhouse_cxc_id',
        'vendedor_id',
        'tipo',
        'monto_informado',
        'nota',
        'estado_alerta',
        'revisada_por',
        'fecha_revision',
    ];

    protected $casts = [
        'fecha_revision' => 'datetime',
        'monto_informado' => 'decimal:2',
    ];

    public function cxc()
    {
        return $this->belongsTo(LedhouseCxc::class, 'ledhouse_cxc_id');
    }

    public function vendedor()
    {
        return $this->belongsTo(\App\Models\User::class, 'vendedor_id');
    }

    public function revisador()
    {
        return $this->belongsTo(\App\Models\User::class, 'revisada_por');
    }

    public function evidencias()
    {
        return $this->hasMany(LedhouseCxcEvidencia::class, 'alerta_id');
    }
}
