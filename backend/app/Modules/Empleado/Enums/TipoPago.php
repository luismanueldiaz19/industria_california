<?php

namespace App\Modules\Empleado\Enums;

enum TipoPago: string
{
    case Transferencia = 'transferencia';
    case Efectivo      = 'efectivo';
    case Cheque        = 'cheque';
}

