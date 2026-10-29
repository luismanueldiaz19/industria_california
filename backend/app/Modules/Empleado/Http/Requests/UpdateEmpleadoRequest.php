<?php

namespace App\Modules\Empleado\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateEmpleadoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $id = $this->route('empleado')?->id ?? $this->route('empleado');

        return [
            'cedula'            => "nullable|string|max:20|unique:empleados,cedula,{$id}",
            'nombres'           => 'nullable|string|max:100',
            'apellidos'         => 'nullable|string|max:100',
            'ocupacion'         => 'nullable|string|max:120',
            'departamento'      => 'nullable|string|max:80',
            'telefono'          => 'nullable|string|max:30',
            'email'             => 'nullable|email|max:120',
            'direccion'         => 'nullable|string',
            'salario_mensual'   => 'nullable|numeric|min:0',
            'aplica_afp'        => 'nullable|boolean',
            'aplica_ars'        => 'nullable|boolean',
            'aplica_isr'        => 'nullable|boolean',
            'tipo_pago'         => 'nullable|in:transferencia,efectivo,cheque',
            'banco'             => 'nullable|string|max:60',
            'numero_cuenta'     => 'nullable|string|max:50',
            'estado'            => 'nullable|in:activo,inactivo,vacaciones,licencia',
            'fecha_ingreso'     => 'nullable|date',
            'fecha_salida'      => 'nullable|date',
        ];
    }

    public function messages(): array
    {
        return [
            'cedula.unique' => 'Esta cédula ya está registrada para otro empleado.',
        ];
    }
}

