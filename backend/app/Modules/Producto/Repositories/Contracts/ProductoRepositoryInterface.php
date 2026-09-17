<?php

namespace App\Modules\Producto\Repositories\Contracts;

interface ProductoRepositoryInterface
{
    public function all();
    public function find($id);
    public function create(array $data);
    public function update($id, array $data);
    public function delete($id);
}
