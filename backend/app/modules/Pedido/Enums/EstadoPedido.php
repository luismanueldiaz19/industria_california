<?php
namespace App\Modules\Pedido\Enums;

enum EstadoPedido: string
{
    case Borrador = 'borrador';
    case Enviado = 'enviado';
    case Facturado = 'facturado';
    case Cancelado = 'cancelado';
}