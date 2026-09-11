<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class InventarioCategoria extends Model
{
    use HasFactory;

    protected $table = 'inventario_categorias';

    protected $fillable = [
        'nombre',
        'descripcion',
        'activo',
    ];

    protected $casts = [
        'activo' => 'boolean',
    ];

    /**
     * Normaliza el nombre a UPPERCASE antes de guardar.
     */
    public function setNombreAttribute(string $value): void
    {
        $this->attributes['nombre'] = strtoupper(trim($value));
    }

    public function productos()
    {
        return $this->hasMany(InventarioProducto::class, 'categoria_id');
    }
}
