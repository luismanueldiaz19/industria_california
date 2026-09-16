<?php
// app/Modules/Pedido/Http/Requests/StorePedidoRequest.php
namespace App\Modules\Pedido\Http\Requests;

use App\Modules\Pedido\Models\Pedido;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class StorePedidoRequest extends FormRequest
{
    public function authorize(): bool {
        return $this->user()->can('create', Pedido::class);
    }

    public function rules(): array
    {
        return [
            'cliente_id' => ['required', 'integer', 'exists:ledhouse_clientes,id'],
            'ruta_id' => ['nullable', 'integer', 'exists:rutas,id'],
            'comentario' => ['nullable', 'string', 'max:2000'],
            'estado' => ['required', Rule::in(['borrador', 'enviado'])],

            'detalles' => ['required', 'array', 'min:1', 'max:200'],
            'detalles.*.producto_id' => ['required', 'integer', 'exists:inventario_productos,id'],
            'detalles.*.cantidad' => ['required', 'numeric', 'min:0.001'],
            'detalles.*.precio_unitario' => ['required', 'numeric', 'min:0'],
            'detalles.*.observacion' => ['nullable', 'string', 'max:500'],

            'latitud' => ['nullable', 'numeric', 'between:-90,90'],
            'longitud' => ['nullable', 'numeric', 'between:-180,180'],

            'idempotency_key' => ['nullable', 'string', 'size:36', 'uuid'],
        ];
    }

    public function messages(): array {
        return [
            'detalles.required' => 'El pedido debe tener al menos un producto.',
            'detalles.*.producto_id.exists' => 'Uno de los productos seleccionados no existe.',
            'detalles.*.cantidad.min' => 'La cantidad debe ser mayor a cero.',
        ];
    }

    /**
     * Validación que tu controller original no tenía: bloquea
     * productos duplicados dentro del mismo request, antes de
     * que lleguen al Service.
     */
    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator) {
            $detalles = $this->input('detalles', []);
            $productoIds = array_column($detalles, 'producto_id');

            if (count($productoIds) !== count(array_unique($productoIds))) {
                $validator->errors()->add(
                    'detalles',
                    'No puedes enviar el mismo producto dos veces en el mismo pedido.'
                );
            }
        });
    }
}