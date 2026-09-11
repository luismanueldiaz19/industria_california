<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class InventarioMovimiento extends Model
{
    use HasFactory;

    protected $table = 'inventario_movimientos';

    protected $fillable = [
        'producto_id',
        'user_id',
        'tipo',
        'subtipo',
        'cantidad',
        'stock_anterior',
        'stock_resultante',
        'nota',
    ];

    protected $casts = [
        'cantidad'         => 'decimal:3',
        'stock_anterior'   => 'decimal:3',
        'stock_resultante' => 'decimal:3',
    ];

    public function producto()
    {
        return $this->belongsTo(InventarioProducto::class, 'producto_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
