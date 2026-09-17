<?php

namespace App\Modules\Producto\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Categoria extends Model
{
    use HasFactory;

    protected $table = 'categories';

    protected $fillable = [
        'nombre',
        'imagen_path',
    ];

    public function productos()
    {
        return $this->hasMany(Producto::class, 'category_id');
    }
}
