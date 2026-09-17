<?php

namespace App\Modules\Producto\Services;

use App\Modules\Producto\Repositories\Contracts\ProductoRepositoryInterface;

class ProductoService
{
    protected $productoRepository;

    public function __construct(ProductoRepositoryInterface $productoRepository)
    {
        $this->productoRepository = $productoRepository;
    }

    public function getAllProductos()
    {
        return $this->productoRepository->all();
    }

    public function getProductoById($id)
    {
        return $this->productoRepository->find($id);
    }

    public function createProducto(array $data)
    {
        // Si hay lógica de negocio adicional (ej. subir imágenes, validar reglas complejas) va aquí
        return $this->productoRepository->create($data);
    }

    public function updateProducto($id, array $data)
    {
        return $this->productoRepository->update($id, $data);
    }

    public function deleteProducto($id)
    {
        return $this->productoRepository->delete($id);
    }
}
