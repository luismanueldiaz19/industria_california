<?php

namespace App\Modules\CuentasPorCobrar\Http\Resources;

use App\Modules\Cliente\Http\Resources\ClienteResource;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CuentaPorCobrarResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                   => $this->id,
            'documento'            => $this->documento,
            'cliente_id'           => $this->cliente_id,
            'vendedor_id'          => $this->vendedor_id,
            'monto_factura'        => (float) $this->monto_factura,
            'monto_pagado'         => (float) $this->monto_pagado,
            'monto_pendiente'      => (float) $this->monto_pendiente,
            'fecha_factura'        => $this->fecha_factura?->format('Y-m-d'),
            'fecha_vencimiento'    => $this->fecha_vencimiento?->format('Y-m-d'),
            'estado'               => $this->estado instanceof \BackedEnum ? $this->estado->value : $this->estado,
            'esta_vencido'         => method_exists($this->resource, 'estaVencido') ? $this->estaVencido() : false,
            
            // Relaciones cargadas condicionalmente
            'cliente'              => new ClienteResource($this->whenLoaded('cliente')),
            'vendedor'             => $this->whenLoaded('vendedor', function () {
                return [
                    'id'    => $this->vendedor->id,
                    'name'  => $this->vendedor->name,
                    'email' => $this->vendedor->email,
                ];
            }),
            'alertas'              => CxcAlertaResource::collection($this->whenLoaded('alertas')),
            'evidencias'           => CxcEvidenciaResource::collection($this->whenLoaded('evidencias')),
            'soportes'             => CxcSoporteResource::collection($this->whenLoaded('soportes')),

            // Contadores y agregados si se cargan en la query
            'total_intervenciones' => $this->total_intervenciones ?? 0,
            'alertas_pendientes'   => $this->alertas_pendientes ?? 0,
            'ultima_fecha_visita'  => $this->ultima_fecha_visita,

            'created_at'           => $this->created_at?->toIso8601String(),
            'updated_at'           => $this->updated_at?->toIso8601String(),
        ];
    }
}
