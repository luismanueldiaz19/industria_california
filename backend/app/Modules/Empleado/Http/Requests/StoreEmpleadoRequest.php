<?php

namespace App\Modules\Empleado\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreEmpleadoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'cedula'            => 'required|string|max:20|unique:empleados,cedula',
            'nombres'           => 'required|string|max:100',
            'apellidos'         => 'required|string|max:100',
            'ocupacion'         => 'nullable|string|max:120',
            'departamento'      => 'nullable|string|max:80',
            'telefono'          => 'nullable|string|max:30',
            'email'             => 'nullable|email|max:120',
            'direccion'         => 'nullable|string',
            'salario_mensual'   => 'required|numeric|min:0',
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
            'cedula.required'          => 'La cédula es obligatoria.',
            'cedula.unique'            => 'Esta cédula ya está registrada para otro empleado.',
            'nombres.required'         => 'El nombre del empleado es obligatorio.',
            'apellidos.required'       => 'Los apellidos son obligatorios.',
            'salario_mensual.required' => 'El salario mensual es obligatorio.',
            'salario_mensual.numeric'  => 'El salario mensual debe ser un valor numérico.',
        ];
    }
}

