<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LedhouseCxc extends Model
{
    protected $fillable = [
        'documento',
        'cliente_id',
        'vendedor_id',
        'monto_factura',
        'monto_pagado',
        'monto_pendiente',
        'fecha_factura',
        'fecha_vencimiento',
        'estado',
    ];

    public function soportes()
    {
        return $this->hasMany(LedhouseCxcSoporte::class, 'ledhouse_cxc_id');
    }

    public function cliente()
    {
        return $this->belongsTo(LedhouseCliente::class, 'cliente_id');
    }

    public function vendedor()
    {
        return $this->belongsTo(\App\Models\User::class, 'vendedor_id');
    }

    public function alertas()
    {
        return $this->hasMany(LedhouseCxcAlerta::class, 'ledhouse_cxc_id');
    }

    public function evidencias()
    {
        return $this->hasMany(LedhouseCxcEvidencia::class, 'ledhouse_cxc_id');
    }
}

