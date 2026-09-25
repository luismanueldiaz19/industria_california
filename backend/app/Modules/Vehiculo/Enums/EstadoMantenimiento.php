<?php

namespace App\Modules\Vehiculo\Enums;

enum EstadoMantenimiento: string
{
    case Pendiente  = 'pendiente';
    case EnProceso  = 'en_proceso';
    case Resuelto   = 'resuelto';
}
