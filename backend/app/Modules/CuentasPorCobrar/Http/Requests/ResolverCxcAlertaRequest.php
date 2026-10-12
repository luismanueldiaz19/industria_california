<?php

namespace App\Modules\CuentasPorCobrar\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ResolverCxcAlertaRequest extends FormRequest
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
}
