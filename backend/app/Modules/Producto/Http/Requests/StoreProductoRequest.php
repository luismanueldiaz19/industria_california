<?php

namespace App\Modules\Producto\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreProductoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true; // Asumimos que la autorización se maneja en middleware o policy
    }

    protected function prepareForValidation()
    {
        if ($this->has('unidad') && $this->unidad !== null) {
            $this->merge([
                'unidad' => strtoupper(trim($this->unidad)),
            ]);
        }
    }

    public function rules(): array
    {
        return [
            'codigo' => 'nullable|string|unique:products,codigo',
            'descripcion' => 'required|string|max:255',
            'parent_id' => 'nullable|exists:products,id',
            'imagen_producto' => 'nullable|string', // Cambiar si manejas archivos (ej. 'nullable|image|max:1024')
            'cant_x_packages' => 'nullable|integer',
            'medidas' => 'nullable|string|max:255',
            'capacidad' => 'nullable|string|max:255',
            'unidad' => 'nullable|string|max:50',
            'precio' => 'nullable|numeric|min:0',
            'costo' => 'nullable|numeric|min:0',
            'stock' => 'nullable|numeric|min:0',
            'stock_minimo' => 'nullable|numeric|min:0',
            'stock_maximo' => 'nullable|numeric|min:0',
            'category_id' => 'required|exists:categories,id',
            'activo' => 'boolean',
        ];
    }
}
