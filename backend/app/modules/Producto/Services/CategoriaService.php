<?php

namespace App\Modules\Producto\Services;

use App\Modules\Producto\Repositories\Contracts\CategoriaRepositoryInterface;

class CategoriaService
{
    protected $categoriaRepository;

    public function __construct(CategoriaRepositoryInterface $categoriaRepository)
    {
        $this->categoriaRepository = $categoriaRepository;
    }

    public function getAllCategorias()
    {
        return $this->categoriaRepository->all();
    }

    public function getCategoriaById($id)
    {
        return $this->categoriaRepository->find($id);
    }

    public function createCategoria(array $data)
    {
        return $this->categoriaRepository->create($data);
    }

    public function updateCategoria($id, array $data)
    {
        return $this->categoriaRepository->update($id, $data);
    }

    public function deleteCategoria($id)
    {
        return $this->categoriaRepository->delete($id);
    }
}
