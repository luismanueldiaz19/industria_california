<?php

namespace App\Modules\Empleado\Enums;

enum EstadoEmpleado: string
{
    case Activo     = 'activo';
    case Inactivo   = 'inactivo';
    case Vacaciones = 'vacaciones';
    case Licencia   = 'licencia';
}

