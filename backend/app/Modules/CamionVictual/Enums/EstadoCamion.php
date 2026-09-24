<?php
namespace App\Modules\CamionVictual\Enums;

enum EstadoCamion: string
{
    case Armando = 'armando';
    case Listo   = 'listo';
    case EnRuta  = 'en_ruta';
    case Cerrado = 'cerrado';
    case Vacio   = 'vacio';
}
