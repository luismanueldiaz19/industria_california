<?php

namespace App\Modules\CuentasPorCobrar\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CxcAlertaResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'ledhouse_cxc_id' => $this->ledhouse_cxc_id,
            'vendedor_id'     => $this->vendedor_id,
            'tipo'            => $this->tipo,
            'monto_informado' => $this->monto_informado !== null ? (float) $this->monto_informado : null,
            'nota'            => $this->nota,
            'estado_alerta'   => $this->estado_alerta instanceof \BackedEnum ? $this->estado_alerta->value : $this->estado_alerta,
            'revisada_por'    => $this->revisada_por,
            'fecha_revision'  => $this->fecha_revision?->toIso8601String(),
            'vendedor'        => $this->whenLoaded('vendedor', function () {
                return [
                    'id'   => $this->vendedor->id,
                    'name' => $this->vendedor->name,
                ];
            }),
            'revisador'       => $this->whenLoaded('revisador', function () {
                return [
                    'id'   => $this->revisador->id,
                    'name' => $this->revisador->name,
                ];
            }),
            'evidencias'      => CxcEvidenciaResource::collection($this->whenLoaded('evidencias')),
            'cxc'             => new CuentaPorCobrarResource($this->whenLoaded('cxc')),
            'created_at'      => $this->created_at?->toIso8601String(),
            'updated_at'      => $this->updated_at?->toIso8601String(),
        ];
    }
}
