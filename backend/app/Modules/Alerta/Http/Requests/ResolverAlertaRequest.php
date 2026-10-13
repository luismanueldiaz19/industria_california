<?php

namespace App\Modules\Alerta\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ResolverAlertaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'estado_alerta'  => 'required|in:revisada,procesada',
            'actualizar_cxc' => 'nullable|boolean',
            'monto_pagado'   => 'nullable|numeric|min:0',
            'estado_cxc'     => 'nullable|in:pendiente,pagado,cancelado',
        ];
    }

    public function messages(): array
    {
        return [
            'estado_alerta.required' => 'El estado de la alerta es obligatorio.',
            'estado_alerta.in'       => 'El estado de la alerta debe ser revisada o procesada.',
            'monto_pagado.numeric'   => 'El monto pagado debe ser un valor numérico.',
            'estado_cxc.in'          => 'El estado de la CXC debe ser pendiente, pagado o cancelado.',
        ];
    }
}
