<?php

namespace App\Modules\Alerta\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ResolverGrupoAlertaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'estado_alerta'          => 'required|in:revisada,procesada',
            'actualizar_cxc'         => 'nullable|boolean',
            'items'                  => 'nullable|array',
            'items.*.alerta_id'      => 'required|integer',
            'items.*.monto_pagado'   => 'required|numeric|min:0',
        ];
    }

    public function messages(): array
    {
        return [
            'estado_alerta.required'       => 'El estado de la alerta es obligatorio.',
            'estado_alerta.in'             => 'El estado de la alerta debe ser revisada o procesada.',
            'items.*.monto_pagado.numeric' => 'El monto pagado debe ser un valor numérico.',
        ];
    }
}
