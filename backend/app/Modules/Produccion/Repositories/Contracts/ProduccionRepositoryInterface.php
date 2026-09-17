<?php

namespace App\Modules\Produccion\Repositories\Contracts;

interface ProduccionRepositoryInterface
{
    public function getAgrupadoPorProducto(int $perPage, ?string $search);
    public function getAgrupadoPorPedido(int $perPage, ?string $search);
    public function getAgrupadoPorCliente(int $perPage, ?string $search);
    public function getAgrupadoPorFecha(int $perPage, ?string $search);
    public function crearOrdenAutomatica(array $datosOrden, array $detalles): \App\Modules\Produccion\Models\OrdenProduccion;
}
