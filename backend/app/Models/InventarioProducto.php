<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class InventarioProducto extends Model
{
    use HasFactory;

    protected $table = 'inventario_productos';

    protected $fillable = [
        'codigo',
        'nombre',
        'unidad',
        'costo',
        'venta',
        'stock',
        'stock_maximo',
        'stock_minimo',
        'categoria_id',
        'imagen_producto',
        'activo',
    ];

    protected $casts = [
        'costo'        => 'decimal:2',
        'venta'        => 'decimal:2',
        'stock'        => 'decimal:3',
        'stock_maximo' => 'decimal:3',
        'stock_minimo' => 'decimal:3',
        'activo'       => 'boolean',
    ];

    /**
     * Normaliza el código a UPPERCASE antes de guardar.
     */
    public function setCodigoAttribute(string $value): void
    {
        $this->attributes['codigo'] = strtoupper(trim($value));
    }

    /**
     * Normaliza el nombre a UPPERCASE antes de guardar.
     */
    public function setNombreAttribute(string $value): void
    {
        $this->attributes['nombre'] = strtoupper(trim($value));
    }

    /**
     * Calcula el estado de stock del producto.
     * Retorna: 'ok', 'alerta', 'critico', 'negativo'
     */
    public function getEstadoStockAttribute(): string
    {
        $stock = (float) $this->stock;

        if ($stock < 0) {
            return 'negativo';
        }

        if ($stock == 0) {
            return 'critico';
        }

        if ($this->stock_minimo !== null && $stock <= (float) $this->stock_minimo) {
            return 'alerta';
        }

        return 'ok';
    }

    public function categoria()
    {
        return $this->belongsTo(InventarioCategoria::class, 'categoria_id');
    }

    public function movimientos()
    {
        return $this->hasMany(InventarioMovimiento::class, 'producto_id');
    }
}
