<?php

namespace App\Modules\ChequeFuturista\Enums;

enum EstadoCheque: string
{
    case Pendiente  = 'pendiente';
    case Depositado = 'depositado';
    case Cancelado  = 'cancelado';
    case Vencido    = 'vencido';
}