<?php

namespace App\Modules\Vehiculo\Enums;

enum TipoEnergia: string
{
    case Gasolina  = 'gasolina';
    case Diesel    = 'diesel';
    case Electrico = 'electrico';
    case Hibrido   = 'hibrido';
    case Gas       = 'gas';
}
