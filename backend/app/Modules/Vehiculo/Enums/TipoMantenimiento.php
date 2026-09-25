<?php

namespace App\Modules\Vehiculo\Enums;

enum TipoMantenimiento: string
{
    case Preventivo = 'preventivo';
    case Correctivo = 'correctivo';
    case Averia     = 'averia';
}
