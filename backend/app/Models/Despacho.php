<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Despacho extends Model
{
    use HasFactory;

    protected $fillable = [
        'vehiculo_id', 'chofer_id', 'fecha_salida', 'fecha_retorno', 
        'estado', 'creado_por'
    ];

    protected $casts = [
        'fecha_salida' => 'datetime',
        'fecha_retorno' => 'datetime',
    ];

    public function vehiculo()
    {
        return $this->belongsTo(Vehiculo::class);
    }

    public function chofer()
    {
        return $this->belongsTo(Chofer::class);
    }

    public function pedidos()
    {
        return $this->belongsToMany(Pedido::class, 'despacho_pedido')
            ->withPivot(['orden_entrega', 'estado_entrega', 'comentario_entrega'])
            ->withTimestamps();
    }

    public function creador()
    {
        return $this->belongsTo(User::class, 'creado_por');
    }
}
