<?php

namespace App\Modules\CuentasPorCobrar\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CxcSoporteResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'ledhouse_cxc_id' => $this->ledhouse_cxc_id,
            'nota'            => $this->nota,
            'fecha'           => $this->fecha?->format('Y-m-d'),
            'fecha_visita'    => $this->fecha_visita?->format('Y-m-d'),
            'created_at'      => $this->created_at?->toIso8601String(),
        ];
    }
}
