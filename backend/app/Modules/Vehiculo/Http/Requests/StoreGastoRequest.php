<?php

namespace App\Modules\Vehiculo\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreGastoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'tipo_gasto'      => 'required|string|max:100',
            'fecha_gasto'     => 'nullable|date',
            'concepto'        => 'required|string|max:255',
            'cantidad'        => 'nullable|numeric|min:0',
            'unidad_medida'   => 'required|string|max:50',
            'precio_unitario' => 'nullable|numeric|min:0',
            'monto_total'     => 'nullable|numeric|min:0',
            'comprobantes'    => 'nullable|array',
            'comprobantes.*'  => 'string',
        ];
    }

    public function messages(): array
    {
        return [
            'concepto.required' => 'El concepto del gasto es obligatorio.',
        ];
    }
}
