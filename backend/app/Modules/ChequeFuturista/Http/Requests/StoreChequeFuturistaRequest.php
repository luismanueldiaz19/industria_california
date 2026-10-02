<?php

namespace App\Modules\ChequeFuturista\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreChequeFuturistaRequest extends FormRequest
{
    public function authorize(): bool { return true; }

    public function rules(): array
    {
        return [
            'id_cliente'  => 'required|integer|exists:ledhouse_clientes,id',
            'id_vendedor' => 'required|integer|exists:users,id',
            'num_cheque'  => 'required|string|max:50',
            'num_pedido'  => 'nullable|string|max:100',
            'monto'       => 'required|numeric|min:0',
            'estado'      => 'nullable|in:pendiente,depositado,cancelado,vencido',
            'comentario'  => 'nullable|string',
        ];
    }

    public function messages(): array
    {
        return [
            'id_cliente.required'  => 'El cliente es obligatorio.',
            'id_cliente.exists'    => 'El cliente seleccionado no existe.',
            'id_vendedor.required' => 'El vendedor es obligatorio.',
            'id_vendedor.exists'   => 'El vendedor seleccionado no existe.',
            'num_cheque.required'  => 'El número de cheque es obligatorio.',
            'monto.required'       => 'El monto es obligatorio.',
            'monto.numeric'        => 'El monto debe ser numérico.',
            'monto.min'            => 'El monto no puede ser negativo.',
        ];
    }
}