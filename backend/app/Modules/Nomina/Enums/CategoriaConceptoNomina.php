<?php

namespace App\Modules\Nomina\Enums;

enum CategoriaConceptoNomina: string
{
    case Salario      = 'salario';
    case Ley          = 'ley';
    case Prestamo     = 'prestamo';
    case Ahorro       = 'ahorro';
    case Novedad      = 'novedad';
    case Adelanto     = 'adelanto';
    case Seguro       = 'seguro';
    case Alimentacion = 'alimentacion';
    case Cxc          = 'cxc';
    case General      = 'general';
}

