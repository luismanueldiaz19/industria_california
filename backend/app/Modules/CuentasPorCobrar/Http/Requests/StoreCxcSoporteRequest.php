<?php

namespace App\Modules\CuentasPorCobrar\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreCxcSoporteRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'nota'         => 'required|string',
            'fecha'        => 'required|date',
            'fecha_visita' => 'nullable|date',
        ];
    }

    public function messages(): array
    {
        return [
            'nota.required'  => 'La nota de soporte es obligatoria.',
            'fecha.required' => 'La fecha es obligatoria.',
        ];
    }
}
