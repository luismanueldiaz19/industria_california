<?php

namespace App\Modules\Vehiculo\Enums;

enum EstadoVehiculo: string
{
    case Disponible      = 'disponible';
    case EnMantenimiento = 'en_mantenimiento';
    case Inactivo        = 'inactivo';
}
