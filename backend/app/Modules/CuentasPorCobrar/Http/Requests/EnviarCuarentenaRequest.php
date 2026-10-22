<?php

namespace App\Modules\CuentasPorCobrar\Http\Requests;

use App\Modules\CuentasPorCobrar\Enums\MotivoCuarentenaCxc;
use Illuminate\Foundation\Http\FormRequest;

class EnviarCuarentenaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return (bool) $this->user()?->hasRole('admin');
    }

    public function rules(): array
    {
        $esMasivo = $this->is('*cxc/cuarentena/masivo');

        return [
            'ids'           => $esMasivo ? 'required|array|min:1' : 'prohibited',
            'ids.*'         => 'integer|exists:ledhouse_cxcs,id',
            'tipo_nota'     => 'required|in:credito,debito',
            'monto_nota'    => $esMasivo ? 'prohibited' : 'nullable|numeric|gt:0',
            'motivo'        => 'required|in:' . implode(',', MotivoCuarentenaCxc::values()),
            'justificacion' => 'required|string|min:10|max:2000',
        ];
    }

    public function messages(): array
    {
        return [
            'ids.required'           => 'Debe seleccionar al menos un documento.',
            'ids.*.exists'           => 'Uno de los documentos seleccionados no existe.',
            'tipo_nota.required'     => 'El tipo de nota es obligatorio.',
            'tipo_nota.in'           => 'El tipo de nota debe ser crédito o débito.',
            'monto_nota.gt'          => 'El monto de la nota debe ser mayor a 0.',
            'motivo.required'        => 'El motivo es obligatorio.',
            'motivo.in'              => 'El motivo seleccionado no es válido.',
            'justificacion.required' => 'La justificación es obligatoria.',
            'justificacion.min'      => 'La justificación debe tener al menos 10 caracteres.',
        ];
    }
}
