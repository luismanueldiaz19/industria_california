<?php

namespace App\Modules\ChequeFuturista\Enums;

enum TipoArchivoDocumento: string
{
    case Pdf  = 'pdf';
    case Jpg  = 'jpg';
    case Jpeg = 'jpeg';
    case Png  = 'png';
}