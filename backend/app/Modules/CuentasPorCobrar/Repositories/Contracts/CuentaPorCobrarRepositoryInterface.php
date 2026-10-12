<?php

namespace App\Modules\CuentasPorCobrar\Repositories\Contracts;

use App\Modules\CuentasPorCobrar\Models\CuentaPorCobrar;

interface CuentaPorCobrarRepositoryInterface
{
    public function getAll(array $filters = [], ?int $perPage = null);
    public function find(int $id): CuentaPorCobrar;
    public function create(array $data): CuentaPorCobrar;
    public function update(int $id, array $data): CuentaPorCobrar;
    public function delete(int $id): bool;
    public function getMisCxc(int $vendedorId, array $filters = [], ?int $perPage = 20): array;
    public function groupedByCliente(array $filters = []);
    public function getResumen(): array;
}
