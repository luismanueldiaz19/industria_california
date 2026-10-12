<?php

namespace App\Modules\CuentasPorCobrar\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CxcEvidenciaResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'ledhouse_cxc_id' => $this->ledhouse_cxc_id,
            'alerta_id'       => $this->alerta_id,
            'subido_por'      => $this->subido_por,
            'nombre_archivo'  => $this->nombre_archivo,
            'ruta_archivo'    => $this->ruta_archivo,
            'url'             => $this->url,
            'tipo_archivo'    => $this->tipo_archivo instanceof \BackedEnum ? $this->tipo_archivo->value : $this->tipo_archivo,
            'subido_por_user' => $this->whenLoaded('subidoPor', function () {
                return [
                    'id'   => $this->subidoPor->id,
                    'name' => $this->subidoPor->name,
                ];
            }),
            'created_at'      => $this->created_at?->toIso8601String(),
        ];
    }
}
