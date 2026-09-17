<?php



// app/Modules/Pedido/Repositories/Contracts/PedidoRepositoryInterface.php
namespace App\Modules\Pedido\Repositories\Contracts;

use App\Modules\Pedido\Models\Pedido;

interface PedidoRepositoryInterface
{
    public function buscarPorIdempotencyKey(string $key): ?Pedido;

    public function crear(array $datosPedido, array $detalles): Pedido;
}