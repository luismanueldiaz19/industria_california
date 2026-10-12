<?php

namespace App\Modules\CuentasPorCobrar\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCuentaPorCobrarRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'documento'         => 'sometimes|string|max:255',
            'cliente_id'        => 'sometimes|exists:ledhouse_clientes,id',
            'vendedor_id'       => 'nullable|exists:users,id',
            'monto_factura'     => 'sometimes|nullable|numeric|min:0',
            'monto_pagado'      => 'sometimes|numeric|min:0',
            'fecha_factura'     => 'sometimes|nullable|date',
            'fecha_vencimiento' => 'sometimes|date',
            'estado'            => 'sometimes|string|in:pendiente,pagado,cancelado',
        ];
    }
}
