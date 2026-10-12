<?php

namespace App\Modules\CuentasPorCobrar\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreCxcAlertaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'tipo'            => 'required|string|max:50',
            'monto_informado' => 'nullable|numeric|min:0',
            'nota'            => 'required|string|max:1000',
        ];
    }

    public function messages(): array
    {
        return [
            'tipo.required' => 'El tipo de alerta es obligatorio.',
            'nota.required' => 'La nota o detalle de la alerta es obligatoria.',
        ];
    }
}
