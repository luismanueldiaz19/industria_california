<?php

namespace App\Modules\CamionVictual\Enums;

enum TipoGastoViaje: string
{
    case Combustible = 'combustible';
    case Dieta       = 'dieta';
    case Peaje       = 'peaje';
    case Hotel       = 'hotel';
    case Otro        = 'otro';
}
