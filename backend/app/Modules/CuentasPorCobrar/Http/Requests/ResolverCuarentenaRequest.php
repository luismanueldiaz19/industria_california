<?php

namespace App\Modules\CuentasPorCobrar\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ResolverCuarentenaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return (bool) $this->user()?->hasRole('admin');
    }

    public function rules(): array
    {
        $esAnular = $this->is('*/anular');

        return [
            'numero_nota_externa' => 'nullable|string|max:100',
            'nota_resolucion'     => ($esAnular ? 'required' : 'nullable') . '|string|max:2000',
        ];
    }

    public function messages(): array
    {
        return [
            'nota_resolucion.required' => 'Debe indicar el motivo de la anulación.',
        ];
    }
}
