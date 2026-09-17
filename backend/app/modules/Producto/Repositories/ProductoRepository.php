<?php

namespace App\Modules\Producto\Repositories;

use App\Modules\Producto\Models\Producto;
use App\Modules\Producto\Repositories\Contracts\ProductoRepositoryInterface;

class ProductoRepository implements ProductoRepositoryInterface
{
    public function all()
    {
        $query = Producto::with(['categoria']);

        if (request()->has('categoria_id')) {
            $query->where('category_id', request('categoria_id'));
        }

        if (request()->has('search')) {
            $search = request('search');
            $query->where(function($q) use ($search) {
                $q->where('descripcion', 'like', '%' . $search . '%');
            });
        }

        if (request()->has('estado_stock')) {
            // Lógica básica de stock si aplica
            $estado = request('estado_stock');
            if ($estado === 'negativo') $query->where('stock', '<', 0);
            if ($estado === 'critico') $query->where('stock', '=', 0);
        }

        $perPage = request('per_page', 100);
        return $query->paginate($perPage);
    }

    public function find($id)
    {
        return Producto::with(['categoria'])->findOrFail($id);
    }

    public function create(array $data)
    {
        return Producto::create($data);
    }

    public function update($id, array $data)
    {
        $producto = $this->find($id);
        $producto->update($data);
        return $producto;
    }

    public function delete($id)
    {
        $producto = $this->find($id);
        return $producto->delete();
    }
}
