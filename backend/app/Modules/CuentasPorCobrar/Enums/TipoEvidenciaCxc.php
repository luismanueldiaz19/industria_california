<?php

namespace App\Modules\CuentasPorCobrar\Enums;

enum TipoEvidenciaCxc: string
{
    case Pdf  = 'pdf';
    case Jpg  = 'jpg';
    case Jpeg = 'jpeg';
    case Png  = 'png';

    public function isImage(): bool
    {
        return in_array($this, [self::Jpg, self::Jpeg, self::Png], true);
    }

    public function isPdf(): bool
    {
        return $this === self::Pdf;
    }
}
