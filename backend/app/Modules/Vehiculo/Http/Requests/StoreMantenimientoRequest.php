<?php

namespace App\Modules\Vehiculo\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreMantenimientoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'tipo'          => 'required|in:preventivo,correctivo,averia',
            'fecha_reporte' => 'nullable|date',
            'descripcion'   => 'required|string|max:1000',
            'costo'         => 'nullable|numeric|min:0',
            'estado'        => 'nullable|in:pendiente,en_proceso,resuelto',
            'evidencias'    => 'nullable|array',
            'evidencias.*'  => 'string',
        ];
    }

    public function messages(): array
    {
        return [
            'tipo.required'        => 'El tipo de mantenimiento es obligatorio.',
            'descripcion.required' => 'La descripción del mantenimiento es obligatoria.',
        ];
    }
}
