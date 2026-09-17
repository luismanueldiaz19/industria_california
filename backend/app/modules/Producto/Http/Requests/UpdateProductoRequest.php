<?php

namespace App\Modules\Producto\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateProductoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $productoId = $this->route('producto');

        return [
            'codigo' => 'nullable|string|unique:products,codigo,' . $productoId,
            'descripcion' => 'sometimes|required|string|max:255',
            'parent_id' => 'nullable|exists:products,id',
            'imagen_producto' => 'nullable|string',
            'cant_x_packages' => 'nullable|integer',
            'medidas' => 'nullable|string|max:255',
            'capacidad' => 'nullable|string|max:255',
            'unidad' => 'nullable|string|in:UNIDAD,LIBRA,KG,OTRO,MTS,LB,PIES',
            'precio' => 'nullable|numeric|min:0',
            'costo' => 'nullable|numeric|min:0',
            'stock' => 'nullable|numeric|min:0',
            'stock_minimo' => 'nullable|numeric|min:0',
            'stock_maximo' => 'nullable|numeric|min:0',
            'category_id' => 'sometimes|required|exists:categories,id',
            'activo' => 'boolean',
        ];
    }
}
