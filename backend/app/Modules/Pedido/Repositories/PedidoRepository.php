<?php
// app/Modules/Pedido/Repositories/PedidoRepository.php
namespace App\Modules\Pedido\Repositories;

use App\Modules\Pedido\Models\Pedido;
use App\Modules\Pedido\Repositories\Contracts\PedidoRepositoryInterface;

class PedidoRepository implements PedidoRepositoryInterface
{
 

    public function buscarPorIdempotencyKey(string $key): ?Pedido {
        return Pedido::where('idempotency_key', $key)
            ->with('detalles')
            ->first();
    }

    public function crear(array $datosPedido, array $detalles): Pedido
    {
        $pedido = Pedido::create($datosPedido);
        $pedido->detalles()->createMany($detalles);

        return $pedido->load('detalles');
    }
}