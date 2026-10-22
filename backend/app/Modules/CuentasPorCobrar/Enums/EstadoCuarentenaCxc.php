<?php

namespace App\Modules\CuentasPorCobrar\Enums;

enum EstadoCuarentenaCxc: string
{
    case Pendiente = 'pendiente';
    case Aplicada  = 'aplicada';
    case Anulada   = 'anulada';

    public function label(): string
    {
        return match ($this) {
            self::Pendiente => 'Pendiente',
            self::Aplicada  => 'Aplicada',
            self::Anulada   => 'Anulada',
        };
    }
}
