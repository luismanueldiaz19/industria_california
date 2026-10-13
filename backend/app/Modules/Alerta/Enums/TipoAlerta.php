<?php

namespace App\Modules\Alerta\Enums;

enum TipoAlerta: string
{
    case PagoRecibido = 'pago_recibido';
    case Consulta     = 'consulta';
    case Credito      = 'credito';
    case Debito       = 'debito';
    case Devolucion   = 'devolucion';
    case Retencion    = 'retencion';
    case Informacion  = 'informacion';

    public function label(): string
    {
        return match ($this) {
            self::PagoRecibido => 'Pago Recibido',
            self::Consulta     => 'Consulta de Factura',
            self::Credito      => 'Nota de Crédito',
            self::Debito       => 'Nota de Débito',
            self::Devolucion   => 'Devolución de Mercancía',
            self::Retencion    => 'Retención Fiscal',
            self::Informacion  => 'Información General',
        };
    }
}
