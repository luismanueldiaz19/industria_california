<?php

namespace App\Modules\Producto\Imports;

use App\Modules\Producto\Models\Producto;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;

class ProductosCategoriaImport implements ToModel, WithHeadingRow
{
    protected $categoriaId;

    public function __construct($categoriaId)
    {
        $this->categoriaId = $categoriaId;
    }

    public function model(array $row)
    {
        // Skip if required fields are missing
        if (empty($row['descripcion']) || !isset($row['precios'])) {
            return null;
        }

        // Clean up price (e.g. remove $ and spaces) if it comes as string
        $precio = is_string($row['precios']) 
            ? floatval(str_replace(['$', ' ', ','], '', $row['precios']))
            : floatval($row['precios']);

        // Update or Create based on multiple fields to prevent overwriting items with the same description
        return Producto::updateOrCreate(
            [
                'descripcion' => trim($row['descripcion']),
                'category_id' => $this->categoriaId,
                'medidas' => $row['medidas'] ?? null,
                'capacidad' => $row['capacidad'] ?? null,
            ],
            [
                'cant_x_packages' => $row['cant_x_packages'] ?? null,
                'unidad' => !empty($row['unidad']) ? strtoupper(trim($row['unidad'])) : 'UNIDAD',
                'precio' => $precio,
            ]
        );
    }
}
