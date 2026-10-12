<?php

namespace App\Modules\Cliente\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateClienteRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $clienteParam = $this->route('cliente') ?? $this->route('id');
        $id = is_object($clienteParam) ? $clienteParam->id : $clienteParam;

        return [
            'id_cliente_externo' => 'required|string|max:100|unique:ledhouse_clientes,id_cliente_externo,' . $id,
            'nombre'             => 'required|string|max:255',
            'whatsapp'           => 'nullable|string|max:50',
            'direccion'          => 'nullable|string|max:500',
            'tipo_documento'     => 'nullable|string|in:Cédula,RNC',
            'documento'          => 'nullable|string|max:50',
            'limite_credito'     => 'nullable|numeric|min:0',
            'dias_credito'       => 'nullable|integer|min:0',
            'latitud'            => 'nullable|numeric',
            'longitud'           => 'nullable|numeric',
        ];
    }
}
