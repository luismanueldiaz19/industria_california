<?php

namespace App\Modules\CuentasPorCobrar\Enums;

enum TipoNotaCxc: string
{
    case Credito = 'credito';
    case Debito  = 'debito';

    public function label(): string
    {
        return match ($this) {
            self::Credito => 'Nota de Crédito',
            self::Debito  => 'Nota de Débito',
        };
    }
}
