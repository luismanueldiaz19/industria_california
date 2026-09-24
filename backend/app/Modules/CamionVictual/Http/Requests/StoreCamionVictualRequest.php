<?php

namespace App\Modules\CamionVictual\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreCamionVictualRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'chofer_id' => 'required|exists:choferes,id',
            'vendedor_id' => 'nullable|exists:users,id',
            'nombre'    => 'nullable|string|max:100',
            'minimo_salida' => 'nullable|numeric|min:0',
            'notas'     => 'nullable|string|max:500',
        ];
    }

    public function messages(): array
    {
        return [
            'chofer_id.required' => 'Debes seleccionar un chofer.',
            'chofer_id.exists'   => 'El chofer seleccionado no existe.',
        ];
    }
}
