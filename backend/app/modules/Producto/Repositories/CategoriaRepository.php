<?php

namespace App\Modules\Producto\Repositories;

use App\Modules\Producto\Models\Categoria;
use App\Modules\Producto\Repositories\Contracts\CategoriaRepositoryInterface;

class CategoriaRepository implements CategoriaRepositoryInterface
{
    public function all()
    {
        return Categoria::all();
    }

    public function find($id)
    {
        return Categoria::findOrFail($id);
    }

    public function create(array $data)
    {
        return Categoria::create($data);
    }

    public function update($id, array $data)
    {
        $categoria = $this->find($id);
        $categoria->update($data);
        return $categoria;
    }

    public function delete($id)
    {
        $categoria = $this->find($id);
        return $categoria->delete();
    }
}
