<?php

namespace App\Modules\ChequeFuturista\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateChequeFuturistaRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'id_cliente'  => 'nullable|integer|exists:ledhouse_clientes,id',
            'id_vendedor' => 'nullable|integer|exists:users,id',
            'num_cheque'  => 'nullable|string|max:50',
            'num_pedido'  => 'nullable|string|max:100',
            'estado'      => 'nullable|in:pendiente,depositado,cancelado,vencido',
            'comentario'  => 'nullable|string',
            'fecha_deposito' => 'nullable|date',
        ];
    }

    public function messages(): array
    {
        return [
            'estado.in'            => 'El estado debe ser pendiente, depositado, cancelado o vencido.',
            'fecha_deposito.date'  => 'La fecha de depósito debe ser una fecha válida.',
        ];
    }
}