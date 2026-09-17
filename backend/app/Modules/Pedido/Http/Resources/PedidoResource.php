<?php

namespace App\Modules\Pedido\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PedidoResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        
        // En lugar de devolver todo con parent::toArray($request), 
        // mapeamos exactamente lo que el frontend necesita.
        return [
            'id' => $this->id,
            'numero_pedido' => $this->numero_pedido,
            'fecha_pedido' => $this->fecha_pedido,
            'cliente_id' => $this->cliente_id,
            'cliente' => $this->cliente,
            'total' => $this->total,
            'estado' => $this->estado,
        ];

    }
}
