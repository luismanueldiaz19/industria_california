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

    // delete(), enviar() separado y facturar() quedan pendientes
    // hasta que existan los roles/permisos correspondientes.
}

// class PedidoPolicy
// {
//     public function viewAny(User $user): bool
//     {
//         return $user->can('ver_pedidos');
//     }

//     public function view(User $user, Pedido $pedido): bool
//     {
//         return $user->can('ver_pedidos');
//     }

//     public function create(User $user): bool
//     {
//         return $user->can('crear_pedidos');
//     }

//     public function update(User $user, Pedido $pedido): bool
//     {
//         return $user->can('editar_pedidos')
//             && $pedido->vendedor_id === $user->id
//             && $pedido->estado === EstadoPedido::Borrador;
//     }

//    public function delete(User $user, Pedido $pedido): bool {
//     return $user->can('eliminar_pedidos');
// }

//     public function enviar(User $user, Pedido $pedido): bool
//     {
//         return $user->can('enviar_pedidos')
//             && $pedido->vendedor_id === $user->id
//             && $pedido->estado === EstadoPedido::Borrador;
//     }

//     public function facturar(User $user, Pedido $pedido): bool
//     {
//         return $user->can('facturar_pedidos')
//             && $pedido->estado === EstadoPedido::Enviado;
//     }
// }