<?php

namespace App\Modules\Alerta\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreAlertaLoteRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * La app envía la petición como multipart (por el archivo), por eso
     * `items` llega como string JSON y se decodifica aquí.
     */
    protected function prepareForValidation(): void
    {
        $items = $this->input('items');

        if (is_string($items)) {
            $decoded = json_decode($items, true);
            $this->merge(['items' => is_array($decoded) ? $decoded : []]);
        }
    }

    public function rules(): array
    {
        return [
            'tipo'           => 'required|string|max:50',
            'nota'           => 'required|string|max:1000',
            'monto_total'    => 'required|numeric|min:0.01',
            'items'          => 'required|array|min:2',
            'items.*.cxc_id' => 'required|integer|distinct|exists:ledhouse_cxcs,id',
            'items.*.monto'  => 'required|numeric|min:0.01',
            'file'           => 'required|file|mimes:pdf,jpg,jpeg,png|max:10240',
        ];
    }

    public function messages(): array
    {
        return [
            'tipo.required'           => 'El concepto o tipo de alerta es obligatorio.',
            'nota.required'           => 'La nota explicativa es obligatoria.',
            'monto_total.required'    => 'El monto total del pago es obligatorio.',
            'items.required'          => 'Debes seleccionar las facturas del pago agrupado.',
            'items.min'               => 'Un pago agrupado debe incluir al menos 2 facturas.',
            'items.*.cxc_id.distinct' => 'Hay facturas repetidas en el pago agrupado.',
            'items.*.cxc_id.exists'   => 'Una de las facturas seleccionadas no existe.',
            'items.*.monto.min'       => 'Cada factura debe tener un monto mayor que cero.',
            'file.required'           => 'El comprobante de pago es obligatorio.',
            'file.mimes'              => 'El comprobante debe ser PDF, JPG o PNG.',
            'file.max'                => 'El comprobante no puede superar 10 MB.',
        ];
    }
}
