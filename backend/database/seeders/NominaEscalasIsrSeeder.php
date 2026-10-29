<?php

namespace Database\Seeders;

use App\Modules\Nomina\Models\NominaEscalaIsr;
use Illuminate\Database\Seeder;

class NominaEscalasIsrSeeder extends Seeder
{
    public function run(): void
    {
        $escalas2026 = [
            [
                'anio'                    => 2026,
                'desde_mensual'           => 0.00,
                'hasta_mensual'           => 34685.00,
                'tasa_porcentaje'         => 0.00,
                'impuesto_base_mensual'   => 0.00,
                'excedente_desde_mensual' => 0.00,
                'descripcion'             => 'Tramo 1: Exento hasta RD$34,685.00 mensual (0%)',
                'activo'                  => true,
            ],
            [
                'anio'                    => 2026,
                'desde_mensual'           => 34685.01,
                'hasta_mensual'           => 52027.42,
                'tasa_porcentaje'         => 15.00,
                'impuesto_base_mensual'   => 0.00,
                'excedente_desde_mensual' => 34685.01,
                'descripcion'             => 'Tramo 2: 15% del excedente de RD$34,685.01',
                'activo'                  => true,
            ],
            [
                'anio'                    => 2026,
                'desde_mensual'           => 52027.43,
                'hasta_mensual'           => 72260.25,
                'tasa_porcentaje'         => 20.00,
                'impuesto_base_mensual'   => 2601.33,
                'excedente_desde_mensual' => 52027.43,
                'descripcion'             => 'Tramo 3: RD$2,601.33 + 20% del excedente de RD$52,027.43',
                'activo'                  => true,
            ],
            [
                'anio'                    => 2026,
                'desde_mensual'           => 72260.26,
                'hasta_mensual'           => null, // En adelante
                'tasa_porcentaje'         => 25.00,
                'impuesto_base_mensual'   => 6648.00,
                'excedente_desde_mensual' => 72260.26,
                'descripcion'             => 'Tramo 4: RD$6,648.00 + 25% del excedente de RD$72,260.26',
                'activo'                  => true,
            ],
        ];

        foreach ($escalas2026 as $item) {
            NominaEscalaIsr::updateOrCreate(
                [
                    'anio'          => $item['anio'],
                    'desde_mensual' => $item['desde_mensual'],
                ],
                $item
            );
        }
    }
}

