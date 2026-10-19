<?php

namespace App\Modules\Vehiculo\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreGastoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $merge = [];
        if ($this->has('concepto')) {
            $merge['concepto'] = mb_strtoupper(trim($this->concepto), 'UTF-8');
        }
        if ($this->has('tipo_gasto')) {
            $merge['tipo_gasto'] = mb_strtoupper(trim($this->tipo_gasto), 'UTF-8');
        }
        if ($this->has('unidad_medida')) {
            $merge['unidad_medida'] = mb_strtoupper(trim($this->unidad_medida), 'UTF-8');
        }
        if ($this->has('comprobante') && is_string($this->comprobante)) {
            $comp = mb_strtoupper(trim($this->comprobante), 'UTF-8');
            $merge['comprobante'] = $comp !== '' ? $comp : null;
            if ($comp !== '') {
                $merge['comprobantes'] = [$comp];
            }
        }
        if (!empty($merge)) {
            $this->merge($merge);
        }
    }

    public function rules(): array
    {
        return [
            'vehiculo_id'     => 'nullable|exists:vehiculos,id',
            'tipo_gasto'      => 'required|string|max:100',
            'fecha_gasto'     => 'nullable|date',
            'concepto'        => 'required|string|max:255',
            'cantidad'        => 'nullable|numeric|min:0',
            'unidad_medida'   => 'nullable|string|max:50',
            'precio_unitario' => 'nullable|numeric|min:0',
            'monto_total'     => 'nullable|numeric|min:0',
            'comprobante'     => 'nullable|string|max:100',
            'comprobantes'    => 'nullable|array',
            'comprobantes.*'  => 'string',
        ];
    }

    public function messages(): array
    {
        return [
            'concepto.required' => 'El concepto del gasto es obligatorio.',
        ];
    }
}
