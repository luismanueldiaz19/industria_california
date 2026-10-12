<?php

namespace App\Modules\Cliente\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class ClienteResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id'                 => $this->id,
            'id_cliente_externo' => $this->id_cliente_externo,
            'nombre'             => $this->nombre,
            'whatsapp'           => $this->whatsapp,
            'direccion'          => $this->direccion,
            'tipo_documento'     => $this->tipo_documento,
            'documento'          => $this->documento,
            'limite_credito'     => $this->limite_credito,
            'dias_credito'       => $this->dias_credito,
            'latitud'            => $this->latitud,
            'longitud'           => $this->longitud,
            'created_at'         => $this->created_at?->toISOString(),
            'updated_at'         => $this->updated_at?->toISOString(),
        ];
    }
}
