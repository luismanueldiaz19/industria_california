<?php

namespace App\Modules\Nomina\Enums;

enum EstadoNomina: string
{
    case Borrador  = 'borrador';
    case Calculada = 'calculada';
    case Aprobada  = 'aprobada';
    case Pagada    = 'pagada';
    case Anulada   = 'anulada';
}

