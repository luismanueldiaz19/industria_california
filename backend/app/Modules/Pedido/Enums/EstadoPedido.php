<?php
namespace App\Modules\Pedido\Enums;

enum EstadoPedido: string
{
    case Borrador = 'borrador';
    case Enviado = 'enviado';
    case Facturado = 'facturado';
    case Entregado = 'entregado';
    case Cancelado = 'cancelado';
}