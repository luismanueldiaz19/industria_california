<?php

namespace App\Modules\ChequeFuturista\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ChequeFuturistaResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'id_cliente' => $this->id_cliente,
            'id_vendedor' => $this->id_vendedor,
            'num_cheque' => $this->num_cheque,
            'num_pedido' => $this->num_pedido,
            'monto' => $this->monto,
            'estado' => $this->estado,
            'comentario' => $this->comentario,
            'created_by' => $this->created_by,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            
            // Relaciones
            'cliente' => $this->whenLoaded('cliente'),
            'vendedor' => $this->whenLoaded('vendedor'),
            'creador' => $this->whenLoaded('creador'),
            'documentos' => $this->whenLoaded('documentos'),
        ];
    }
}
