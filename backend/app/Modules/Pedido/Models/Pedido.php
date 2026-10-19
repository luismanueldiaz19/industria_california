<?php

namespace App\Modules\Pedido\Models;

use App\Modules\Pedido\Enums\EstadoPedido;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use App\Models\LedhouseCliente;
use App\Models\Ruta;
use App\Models\User;
use App\Models\Despacho;

class Pedido extends Model
{
    use HasFactory;

    protected $fillable = [
        'cliente_id',
        'ruta_id',
        'vendedor_id',
        'facturador_id',
        'num_factura',
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

    protected static function booted(): void
    {
        static::updating(function (Pedido $pedido) {
            $estadoOriginal = is_object($pedido->getOriginal('estado'))
                ? $pedido->getOriginal('estado')->value
                : (string) $pedido->getOriginal('estado');

            if ($estadoOriginal === 'entregado') {
                throw new \Exception('Un pedido ENTREGADO no puede ser modificado. Ningún campo de su tabla puede ser actualizado.');
            }
        });

        static::deleting(function (Pedido $pedido) {
            $estado = is_object($pedido->estado) ? $pedido->estado->value : (string) $pedido->estado;
            if ($estado === 'facturado' || !empty(trim((string) $pedido->num_factura))) {
                throw new \Exception('Un pedido FACTURADO no puede ser eliminado del sistema.');
            }
            if ($estado === 'entregado') {
                throw new \Exception('Un pedido ENTREGADO no puede ser eliminado ya que finalizó su ciclo de despacho.');
            }
        });
    }

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

    public function ordenProduccion()
    {
        return $this->hasOne(\App\Modules\Produccion\Models\OrdenProduccion::class, 'pedido_id');
    }
}
