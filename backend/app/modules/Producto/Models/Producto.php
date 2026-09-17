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
