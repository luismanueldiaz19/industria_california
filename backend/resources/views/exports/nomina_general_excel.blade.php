<table>
    <thead>
        <tr>
            <th colspan="14" style="font-size: 16px; font-weight: bold; text-align: center; background-color: #0F172A; color: #FFFFFF;">
                INDUSTRIA CALIFORNIA, SRL
            </th>
        </tr>
        <tr>
            <th colspan="14" style="font-size: 12px; font-weight: bold; text-align: center; background-color: #1E293B; color: #FFFFFF;">
                REPORTE GENERAL DE NÓMINA — RNC: 132839935
            </th>
        </tr>
        <tr>
            <th colspan="14" style="font-size: 10px; text-align: center; background-color: #F8FAFC; color: #334155;">
                Código: {{ $nomina->codigo }} | {{ $nomina->titulo }} | Del {{ $fechaInicio }} al {{ $fechaFin }} | Pago: {{ $fechaPago }} | Estado: {{ strtoupper($nomina->estado->value ?? $nomina->estado) }}
            </th>
        </tr>
        <tr>
            <th colspan="14"></th>
        </tr>
        <tr style="background-color: #2563EB; color: #FFFFFF; font-weight: bold;">
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: center; width: 6px;">#</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: center; width: 16px;">CÉDULA</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: left; width: 30px;">COLABORADOR</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: left; width: 20px;">CARGO</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: left; width: 18px;">DEPARTAMENTO</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: right; width: 16px;">SALARIO MENSUAL</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: right; width: 16px;">SALARIO PERIODO</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: right; width: 16px;">TOTAL INGRESOS</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: right; width: 14px;">AFP</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: right; width: 14px;">ARS</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: right; width: 16px;">RETENCIÓN ISR</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: right; width: 16px;">PRÉSTAMOS / OTROS</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: right; width: 16px;">TOTAL DEDUC.</th>
            <th style="background-color: #0F172A; color: #FFFFFF; font-weight: bold; text-align: right; width: 18px;">NETO A PAGAR</th>
        </tr>
    </thead>
    <tbody>
        @php
            $totSalarioMensual = 0;
            $totSalarioPeriodo = 0;
            $totIngresos = 0;
            $totAfp = 0;
            $totArs = 0;
            $totIsr = 0;
            $totOtrosDeduc = 0;
            $totDeducciones = 0;
            $totNeto = 0;
        @endphp

        @foreach($nomina->detalles as $index => $det)
            @php
                $emp = $det->empleado;
                $totSalarioMensual += $det->salario_mensual;
                $totSalarioPeriodo += $det->salario_periodo;
                $totIngresos += $det->total_ingresos;
                $totDeducciones += $det->total_deducciones;
                $totNeto += $det->neto_pagar;

                $afpMonto = 0;
                $arsMonto = 0;
                $isrMonto = 0;
                $otrosDeduc = 0;

                foreach($det->conceptos as $c) {
                    if ($c->tipo->value ?? $c->tipo == 'deduccion') {
                        $cod = $c->concepto?->codigo ?? '';
                        if ($cod === 'AFP_EMP') {
                            $afpMonto += $c->monto;
                        } elseif ($cod === 'ARS_EMP') {
                            $arsMonto += $c->monto;
                        } elseif ($cod === 'RET_ISR') {
                            $isrMonto += $c->monto;
                        } else {
                            $otrosDeduc += $c->monto;
                        }
                    }
                }

                $totAfp += $afpMonto;
                $totArs += $arsMonto;
                $totIsr += $isrMonto;
                $totOtrosDeduc += $otrosDeduc;

                $bg = ($index % 2 == 0) ? '#FFFFFF' : '#F8FAFC';
            @endphp
            <tr style="background-color: {{ $bg }};">
                <td style="text-align: center;">{{ $index + 1 }}</td>
                <td style="text-align: center;">{{ $emp?->cedula ?? '—' }}</td>
                <td style="text-align: left; font-weight: bold;">{{ $emp?->nombre_completo ?? '—' }}</td>
                <td style="text-align: left;">{{ $emp?->ocupacion ?? '—' }}</td>
                <td style="text-align: left;">{{ $emp?->departamento ?? '—' }}</td>
                <td style="text-align: right;">{{ number_format($det->salario_mensual, 2, '.', '') }}</td>
                <td style="text-align: right;">{{ number_format($det->salario_periodo, 2, '.', '') }}</td>
                <td style="text-align: right; color: #16A34A; font-weight: bold;">{{ number_format($det->total_ingresos, 2, '.', '') }}</td>
                <td style="text-align: right;">{{ number_format($afpMonto, 2, '.', '') }}</td>
                <td style="text-align: right;">{{ number_format($arsMonto, 2, '.', '') }}</td>
                <td style="text-align: right;">{{ number_format($isrMonto, 2, '.', '') }}</td>
                <td style="text-align: right;">{{ number_format($otrosDeduc, 2, '.', '') }}</td>
                <td style="text-align: right; color: #DC2626; font-weight: bold;">{{ number_format($det->total_deducciones, 2, '.', '') }}</td>
                <td style="text-align: right; color: #2563EB; font-weight: bold;">{{ number_format($det->neto_pagar, 2, '.', '') }}</td>
            </tr>
        @endforeach
    </tbody>
    <tfoot>
        <tr style="background-color: #E2E8F0; font-weight: bold; border-top: 2px solid #0F172A;">
            <td colspan="5" style="text-align: right; font-weight: bold;">TOTALES GENERALES (RD$):</td>
            <td style="text-align: right; font-weight: bold;">{{ number_format($totSalarioMensual, 2, '.', '') }}</td>
            <td style="text-align: right; font-weight: bold;">{{ number_format($totSalarioPeriodo, 2, '.', '') }}</td>
            <td style="text-align: right; font-weight: bold; color: #16A34A;">{{ number_format($totIngresos, 2, '.', '') }}</td>
            <td style="text-align: right; font-weight: bold;">{{ number_format($totAfp, 2, '.', '') }}</td>
            <td style="text-align: right; font-weight: bold;">{{ number_format($totArs, 2, '.', '') }}</td>
            <td style="text-align: right; font-weight: bold;">{{ number_format($totIsr, 2, '.', '') }}</td>
            <td style="text-align: right; font-weight: bold;">{{ number_format($totOtrosDeduc, 2, '.', '') }}</td>
            <td style="text-align: right; font-weight: bold; color: #DC2626;">{{ number_format($totDeducciones, 2, '.', '') }}</td>
            <td style="text-align: right; font-weight: bold; color: #2563EB;">{{ number_format($totNeto, 2, '.', '') }}</td>
        </tr>
    </tfoot>
</table>

