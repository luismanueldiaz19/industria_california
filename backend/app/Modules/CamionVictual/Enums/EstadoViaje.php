<?php

namespace App\Modules\CamionVictual\Enums;

enum EstadoViaje: string
{
    case EnRuta     = 'en_ruta';
    case Completado = 'completado';
    case Cancelado  = 'cancelado';
}
