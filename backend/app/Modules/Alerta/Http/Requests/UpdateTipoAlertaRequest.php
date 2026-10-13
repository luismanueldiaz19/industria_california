<?php

namespace App\Modules\Alerta\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateTipoAlertaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'tipo' => 'required|string|max:50',
        ];
    }

    public function messages(): array
    {
        return [
            'tipo.required' => 'El tipo o concepto es obligatorio.',
        ];
    }
}
