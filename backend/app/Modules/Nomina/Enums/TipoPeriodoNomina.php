<?php

namespace App\Modules\Nomina\Enums;

enum TipoPeriodoNomina: string
{
    case Quincenal      = 'quincenal';
    case Mensual        = 'mensual';
    case Extraordinaria = 'extraordinaria';
}

