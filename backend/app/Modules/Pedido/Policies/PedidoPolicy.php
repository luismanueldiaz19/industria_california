<?php

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

    public function update(User $user, Pedido $pedido): bool
    {
        if ($user->hasRole('admin')) {
            return true;
        }

        $estado = is_object($pedido->estado) ? $pedido->estado->value : (string) $pedido->estado;

        return ($user->can('editar_pedidos') || $user->hasRole('vendedor'))
            && $pedido->vendedor_id === $user->id
            && in_array($estado, ['borrador', 'cotizacion', 'enviado']);
    }

    public function delete(User $user, Pedido $pedido): bool
    {
        if ($user->hasRole('admin')) {
            return true;
        }

        $estado = is_object($pedido->estado) ? $pedido->estado->value : (string) $pedido->estado;

        return ($user->can('eliminar_pedidos') || $user->hasRole('vendedor'))
            && $pedido->vendedor_id === $user->id
            && in_array($estado, ['borrador', 'cotizacion', 'enviado']);
    }
}

