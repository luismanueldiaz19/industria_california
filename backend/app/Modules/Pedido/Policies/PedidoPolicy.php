<?php

namespace App\Modules\Policies;

use App\Modules\Pedido\Enums\EstadoPedido;
use App\Modules\Pedido\Models\Pedido;
use App\Models\User;

// app/Modules/Pedido/Policies/PedidoPolicy.php
namespace App\Modules\Pedido\Policies;

use App\Modules\Pedido\Enums\EstadoPedido;
use App\Modules\Pedido\Models\Pedido;
use App\Models\User;

class PedidoPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->can('ver_pedidos');
    }

    public function view(User $user, Pedido $pedido): bool
    {
        return $user->can('ver_pedidos');
    }

    public function create(User $user): bool
    {
        return $user->can('crear_pedidos');
    }

    /**
     * También cubre la transición borrador → enviado: mandar un pedido
     * es, técnicamente, una actualización del campo `estado`. No hay
     * un rol separado para "enviar" todavía, así que no se justifica
     * un método enviar() aparte por ahora.
     */
    public function update(User $user, Pedido $pedido): bool
    {
        return $user->can('editar_pedidos')
            && $pedido->vendedor_id === $user->id
            && $pedido->estado === EstadoPedido::Borrador;
    }


}
