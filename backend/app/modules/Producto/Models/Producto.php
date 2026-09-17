<?php

namespace App\Modules\Producto\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Producto extends Model
{
    use HasFactory;

    protected $table = 'products';

    protected $fillable = [
        'codigo',
        'descripcion',
        'parent_id',
        'imagen_producto',
        'cant_x_packages',
        'medidas',
        'capacidad',
        'unidad',
        'precio',
        'costo',
        'stock',
        'stock_maximo',
        'stock_minimo',
        'category_id',
        'activo',
    ];

    protected $casts = [
        'precio' => 'decimal:2',
        'costo' => 'decimal:2',
        'stock' => 'decimal:3',
        'stock_maximo' => 'decimal:3',
        'stock_minimo' => 'decimal:3',
        'activo' => 'boolean',
    ];

    protected $appends = ['estado_stock', 'nombre_completo'];

    /**
     * Devuelve el nombre completo del producto combinando medidas y capacidad.
     */
    public function getNombreCompletoAttribute(): string
    {
        $parts = [
            $this->descripcion,
        ];
        if (!empty($this->medidas)) {
            $parts[] = $this->medidas;
        }
        if (!empty($this->capacidad)) {
            $parts[] = $this->capacidad;
        }
        if (!empty($this->unidad) && strtoupper($this->unidad) !== 'UNIDAD') {
            $parts[] = $this->unidad;
        }
        return strtoupper(trim(implode(' ', $parts)));
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
        return $this->belongsTo(Categoria::class, 'category_id');
    }

    public function parent()
    {
        return $this->belongsTo(Producto::class, 'parent_id');
    }

    public function variants()
    {
        return $this->hasMany(Producto::class, 'parent_id');
    }
}
