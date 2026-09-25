<?php

namespace App\Modules\Vehiculo\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreVehiculoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'ficha'           => 'required|string|max:20|unique:vehiculos,ficha',
            'placa'           => 'nullable|string|max:20',
            'marca'           => 'nullable|string|max:100',
            'modelo'          => 'nullable|string|max:100',
            'anio'            => 'nullable|integer|min:1900|max:' . (date('Y') + 1),
            'tipo_energia'    => 'nullable|in:gasolina,diesel,electrico,hibrido,gas',
            'capacidad_carga' => 'nullable|numeric|min:0',
            'estado'          => 'nullable|in:disponible,en_mantenimiento,inactivo',
        ];
    }

    public function messages(): array
    {
        return [
            'ficha.required' => 'La ficha del vehículo es obligatoria.',
            'ficha.unique'   => 'Ya existe un vehículo con esa ficha.',
        ];
    }
}
