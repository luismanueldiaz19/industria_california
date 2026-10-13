<?php

namespace App\Modules\Alerta\Enums;

enum EstadoAlerta: string
{
    case Pendiente = 'pendiente';
    case Revisada  = 'revisada';
    case Procesada = 'procesada';

    public function label(): string
    {
        return match ($this) {
            self::Pendiente => 'Pendiente',
            self::Revisada  => 'Revisada',
            self::Procesada => 'Procesada',
        };
    }
}
