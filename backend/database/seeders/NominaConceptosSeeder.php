<?php

namespace Database\Seeders;

use App\Modules\Nomina\Models\NominaConcepto;
use Illuminate\Database\Seeder;

class NominaConceptosSeeder extends Seeder
{
    public function run(): void
    {
        $conceptos = [
            // ── INGRESOS ──────────────────────────────────────────
            [
                'codigo'           => 'SALARIO_ORDINARIO',
                'nombre'           => 'Salario Ordinario (Periodo)',
                'tipo'             => 'ingreso',
                'categoria'        => 'salario',
                'es_automatico'    => true,
                'es_cotizable_tss' => true,
                'es_gravable_isr'  => true,
            ],
            [
                'codigo'           => 'HORAS_EXTRAS_35',
                'nombre'           => 'Horas Extras (35%)',
                'tipo'             => 'ingreso',
                'categoria'        => 'novedad',
                'es_automatico'    => false,
                'es_cotizable_tss' => true,
                'es_gravable_isr'  => true,
            ],
            [
                'codigo'           => 'HORAS_EXTRAS_100',
                'nombre'           => 'Horas Extras Feriado/Descanso (100%)',
                'tipo'             => 'ingreso',
                'categoria'        => 'novedad',
                'es_automatico'    => false,
                'es_cotizable_tss' => true,
                'es_gravable_isr'  => true,
            ],
            [
                'codigo'           => 'BENEFICIO_ADICIONAL',
                'nombre'           => 'Beneficio Adicional / Incentivo',
                'tipo'             => 'ingreso',
                'categoria'        => 'general',
                'es_automatico'    => false,
                'es_cotizable_tss' => true,
                'es_gravable_isr'  => true,
            ],
            [
                'codigo'           => 'PAGO_VACACIONES',
                'nombre'           => 'Pago de Vacaciones',
                'tipo'             => 'ingreso',
                'categoria'        => 'ley',
                'es_automatico'    => false,
                'es_cotizable_tss' => true,
                'es_gravable_isr'  => true,
            ],
            [
                'codigo'           => 'COMISIONES',
                'nombre'           => 'Comisiones por Venta',
                'tipo'             => 'ingreso',
                'categoria'        => 'general',
                'es_automatico'    => false,
                'es_cotizable_tss' => true,
                'es_gravable_isr'  => true,
            ],

            // ── DEDUCCIONES DE LEY (TSS E ISR) ────────────────────
            [
                'codigo'           => 'AFP_EMP',
                'nombre'           => 'AFP',
                'tipo'             => 'deduccion',
                'categoria'        => 'ley',
                'es_automatico'    => true,
                'es_porcentual'    => true,
                'porcentaje'       => 2.8700,
                'es_cotizable_tss' => false,
                'es_gravable_isr'  => false,
            ],
            [
                'codigo'           => 'ARS_EMP',
                'nombre'           => 'ARS',
                'tipo'             => 'deduccion',
                'categoria'        => 'ley',
                'es_automatico'    => true,
                'es_porcentual'    => true,
                'porcentaje'       => 3.0400,
                'es_cotizable_tss' => false,
                'es_gravable_isr'  => false,
            ],
            [
                'codigo'           => 'RET_ISR',
                'nombre'           => 'Retención ISR',
                'tipo'             => 'deduccion',
                'categoria'        => 'ley',
                'es_automatico'    => true,
                'es_porcentual'    => false,
                'es_cotizable_tss' => false,
                'es_gravable_isr'  => false,
            ],

            // ── DEDUCCIONES INSTITUCIONALES / PRÉSTAMOS / NOVEDADES ─
            [
                'codigo'           => 'DESC_VACACIONES',
                'nombre'           => 'Descuento por Vacaciones',
                'tipo'             => 'deduccion',
                'categoria'        => 'ley',
            ],
            [
                'codigo'           => 'SEGURO_COMPLEMENTARIO',
                'nombre'           => 'Seguro Dependiente Adicional + Complem.',
                'tipo'             => 'deduccion',
                'categoria'        => 'seguro',
            ],
            [
                'codigo'           => 'DESC_HRS_NO_LABORADAS',
                'nombre'           => 'Descuento Horas No Laboradas',
                'tipo'             => 'deduccion',
                'categoria'        => 'novedad',
            ],
            [
                'codigo'           => 'PRESTAMO_COOPMEDICA',
                'nombre'           => 'Préstamo Coopmedica',
                'tipo'             => 'deduccion',
                'categoria'        => 'prestamo',
            ],
            [
                'codigo'           => 'AHORRO_COOPMEDICA',
                'nombre'           => 'Ahorro Coopmedica',
                'tipo'             => 'deduccion',
                'categoria'        => 'ahorro',
            ],
            [
                'codigo'           => 'PRESTAMO_ADEMI',
                'nombre'           => 'Préstamo Ademi',
                'tipo'             => 'deduccion',
                'categoria'        => 'prestamo',
            ],
            [
                'codigo'           => 'AHORRO_ADEMI',
                'nombre'           => 'Ahorro Ademi',
                'tipo'             => 'deduccion',
                'categoria'        => 'ahorro',
            ],
            [
                'codigo'           => 'BOTELLO',
                'nombre'           => 'Botello / Taller',
                'tipo'             => 'deduccion',
                'categoria'        => 'prestamo',
            ],
            [
                'codigo'           => 'DESC_LICENCIA_FARMACIA',
                'nombre'           => 'Descuento Licencia o Farmacia',
                'tipo'             => 'deduccion',
                'categoria'        => 'general',
            ],
            [
                'codigo'           => 'DESC_FACTURAS_CXC',
                'nombre'           => 'Desc. Facturas CxC',
                'tipo'             => 'deduccion',
                'categoria'        => 'cxc',
            ],
            [
                'codigo'           => 'PRESTAMO_INTERNO',
                'nombre'           => 'Préstamo Interno Empresa',
                'tipo'             => 'deduccion',
                'categoria'        => 'prestamo',
            ],
            [
                'codigo'           => 'COMIDA',
                'nombre'           => 'Comida',
                'tipo'             => 'deduccion',
                'categoria'        => 'alimentacion',
            ],
            [
                'codigo'           => 'AVANCE_SUELDO',
                'nombre'           => 'Avance de Sueldo',
                'tipo'             => 'deduccion',
                'categoria'        => 'adelanto',
            ],
        ];

        foreach ($conceptos as $data) {
            $data['activo'] = true;
            NominaConcepto::updateOrCreate(
                ['codigo' => $data['codigo']],
                $data
            );
        }
    }
}

