<?php

namespace App\Modules\CuentasPorCobrar\Enums;

enum EstadoCxc: string
{
    case Pendiente = 'pendiente';
    case Pagado    = 'pagado';
    case Cancelado = 'cancelado';

    public function label(): string
    {
        return match ($this) {
            self::Pendiente => 'Pendiente',
            self::Pagado    => 'Pagado',
            self::Cancelado => 'Cancelado',
        };
    }
}
