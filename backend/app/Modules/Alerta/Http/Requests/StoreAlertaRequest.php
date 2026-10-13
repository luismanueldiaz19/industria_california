<?php

namespace App\Modules\Alerta\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreAlertaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        if (!$this->has('ledhouse_cxc_id') && $this->has('cxc_id')) {
            $this->merge(['ledhouse_cxc_id' => $this->input('cxc_id')]);
        }
    }

    public function rules(): array
    {
        return [
            'ledhouse_cxc_id' => 'required|exists:ledhouse_cxcs,id',
            'tipo'            => 'required|string|max:50',
            'monto_informado' => 'nullable|numeric|min:0',
            'nota'            => 'required|string|max:1000',
        ];
    }

    public function messages(): array {
        return [
            'ledhouse_cxc_id.required' => 'La cuenta por cobrar es obligatoria.',
            'ledhouse_cxc_id.exists'   => 'La cuenta por cobrar seleccionada no existe.',
            'tipo.required'            => 'El concepto o tipo de alerta es obligatorio.',
            'nota.required'            => 'La nota explicativa es obligatoria.',
        ];
    }
}
