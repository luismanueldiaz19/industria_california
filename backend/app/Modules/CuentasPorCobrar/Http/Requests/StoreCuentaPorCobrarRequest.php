<?php

namespace App\Modules\CuentasPorCobrar\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreCuentaPorCobrarRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'documento'         => 'required|string|max:255',
            'cliente_id'        => 'required|exists:ledhouse_clientes,id',
            'vendedor_id'       => 'nullable|exists:users,id',
            'monto_factura'     => 'required|numeric|min:0',
            'monto_pagado'      => 'nullable|numeric|min:0',
            'fecha_factura'     => 'nullable|date',
            'fecha_vencimiento' => 'required|date',
            'estado'            => 'nullable|string|in:pendiente,pagado,cancelado',
        ];
    }

    public function messages(): array
    {
        return [
            'documento.required'         => 'El número de documento es obligatorio.',
            'cliente_id.required'        => 'Debe seleccionar un cliente válido.',
            'cliente_id.exists'          => 'El cliente seleccionado no existe.',
            'monto_factura.required'     => 'El monto de la factura es obligatorio.',
            'fecha_vencimiento.required' => 'La fecha de vencimiento es obligatoria.',
        ];
    }
}
