<?php
namespace App\Modules\CamionVictual\Enums;

enum EstadoEntrega: string
{
    case Pendiente  = 'pendiente';
    case EnCurso    = 'en_curso';
    case Entregado  = 'entregado';
    case Fallido    = 'fallido';
}
