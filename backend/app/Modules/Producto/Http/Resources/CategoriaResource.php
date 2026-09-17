<?php

namespace App\Modules\Producto\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class CategoriaResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'nombre' => $this->nombre,
            'imagen_path' => $this->imagen_path,
            'imagen_url' => $this->imagen_path ? \Illuminate\Support\Facades\Storage::url($this->imagen_path) : null,
        ];
    }
}
