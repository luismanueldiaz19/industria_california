<?php

namespace App\Modules\Producto\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class ProductoResource extends JsonResource
{
    public function toArray($request)
    {
        return [
            'id' => $this->id,
            'codigo' => $this->codigo,
            'descripcion' => $this->descripcion,
            'parent_id' => $this->parent_id,
            'imagen_producto' => $this->imagen_producto,
            'cant_x_packages' => $this->cant_x_packages,
            'medidas' => $this->medidas,
            'capacidad' => $this->capacidad,
            'unidad' => $this->unidad,
            'precio' => $this->precio,
            'costo' => $this->costo,
            'stock' => $this->stock,
            'category_id' => $this->category_id,
            'activo' => $this->activo,
            'categoria' => $this->whenLoaded('categoria', function() {
                return [
                    'id' => $this->categoria->id,
                    'nombre' => $this->categoria->nombre,
                ];
            }),
            'variants' => ProductoResource::collection($this->whenLoaded('variants')),
        ];
    }
}
