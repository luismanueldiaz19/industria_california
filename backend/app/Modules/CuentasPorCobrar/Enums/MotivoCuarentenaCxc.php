<?php

namespace App\Modules\CuentasPorCobrar\Enums;

enum MotivoCuarentenaCxc: string
{
    case Devolucion        = 'devolucion';
    case Descuento         = 'descuento';
    case DiferenciaPrecio  = 'diferencia_precio';
    case ErrorFacturacion  = 'error_facturacion';
    case Otro              = 'otro';

    public function label(): string
    {
        return match ($this) {
            self::Devolucion       => 'Devolución',
            self::Descuento        => 'Descuento',
            self::DiferenciaPrecio => 'Diferencia de precio',
            self::ErrorFacturacion => 'Error de facturación',
            self::Otro             => 'Otro',
        };
    }

    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
