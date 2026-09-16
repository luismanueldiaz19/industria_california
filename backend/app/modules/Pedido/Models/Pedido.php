<?php

namespace App\Modules\Pedido\Models;

use App\Modules\Pedido\Enums\EstadoPedido;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Pedido extends Model
{
    use HasFactory;

    protected $fillable = [
        'cliente_id',
        'ruta_id',
        'vendedor_id',
        'facturador_id',
        'estado',
        'comentario',
        'total',
        'latitud',
        'longitud',
        'fecha_entrega',
        'nota_produccion',
    ];

    protected $casts = [
        'estado' => EstadoPedido::class,
        'total' => 'decimal:2',
        'latitud' => 'decimal:8',
        'longitud' => 'decimal:8',
        'fecha_entrega' => 'date',
    ];

    public function cliente()
    {
        return $this->belongsTo(LedhouseCliente::class, 'cliente_id');
    }

    public function ruta()
    {
        return $this->belongsTo(Ruta::class, 'ruta_id');
    }

    public function vendedor()
    {
        return $this->belongsTo(User::class, 'vendedor_id');
    }

    public function facturador()
    {
        return $this->belongsTo(User::class, 'facturador_id');
    }

    public function detalles()
    {
        return $this->hasMany(PedidoDetalle::class, 'pedido_id');
    }

    public function despachos()
    {
        return $this->belongsToMany(Despacho::class, 'despacho_pedido')
            ->withPivot(['orden_entrega', 'estado_entrega', 'comentario_entrega'])
            ->withTimestamps();
    }
}
