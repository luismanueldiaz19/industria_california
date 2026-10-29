<table>
    <thead>
        <tr>
            <th colspan="12" style="font-size: 16px; font-weight: bold; text-align: center; background-color: #0F172A; color: #FFFFFF;">
                INDUSTRIA CALIFORNIA, SRL
            </th>
        </tr>
        <tr>
            <th colspan="12" style="font-size: 12px; font-weight: bold; text-align: center; background-color: #1E293B; color: #FFFFFF;">
                CARTERA DE PRÉSTAMOS Y DESCUENTOS RECURRENTES — RNC: 132839935
            </th>
        </tr>
        <tr>
            <th colspan="12" style="font-size: 10px; text-align: center; background-color: #F8FAFC; color: #334155;">
                Fecha de Emisión: {{ now()->format('d/m/Y h:i A') }} | Total Registros: {{ count($recurrentes) }}
            </th>
        </tr>
        <tr>
            <th colspan="12"></th>
        </tr>
        <tr style="background-color: #1E293B; color: #FFFFFF; font-weight: bold;">
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: center; width: 6px;">#</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: center; width: 16px;">CÉDULA</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: left; width: 28px;">COLABORADOR</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: left; width: 18px;">CONCEPTO</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: left; width: 25px;">DESCRIPCIÓN / MOTIVO</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: right; width: 16px;">MONTO TOTAL</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: right; width: 15px;">CUOTA PERIODO</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: center; width: 14px;">CUOTAS PAG.</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: center; width: 14px;">CUOTAS TOT.</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: right; width: 16px;">TOTAL COBRADO</th>
            <th style="background-color: #1E293B; color: #FFFFFF; font-weight: bold; text-align: right; width: 16px;">SALDO PENDIENTE</th>
            <th style="background-color: #0F172A; color: #FFFFFF; font-weight: bold; text-align: center; width: 14px;">ESTADO</th>
        </tr>
    </thead>
    <tbody>
        @php
            $totMonto = 0;
            $totCuota = 0;
            $totCobrado = 0;
            $totSaldo = 0;
        @endphp

        @foreach($recurrentes as $index => $rec)
            @php
                $emp = $rec->empleado;
                $totMonto += $rec->monto_total;
                $totCuota += $rec->monto_cuota;
                $cobrado = $rec->cuotas_pagadas * $rec->monto_cuota;
                $totCobrado += $cobrado;
                $totSaldo += $rec->saldo_restante;
                $bg = ($index % 2 == 0) ? '#FFFFFF' : '#F8FAFC';
            @endphp
            <tr style="background-color: {{ $bg }};">
                <td style="text-align: center;">{{ $index + 1 }}</td>
                <td style="text-align: center;">{{ $emp?->cedula ?? '—' }}</td>
                <td style="text-align: left; font-weight: bold;">{{ $emp?->nombre_completo ?? '—' }}</td>
                <td style="text-align: left;">{{ $rec->concepto?->nombre ?? 'Deducción' }}</td>
                <td style="text-align: left;">{{ $rec->descripcion }}</td>
                <td style="text-align: right;">{{ number_format($rec->monto_total, 2, '.', '') }}</td>
                <td style="text-align: right; font-weight: bold;">{{ number_format($rec->monto_cuota, 2, '.', '') }}</td>
                <td style="text-align: center;">{{ $rec->cuotas_pagadas }}</td>
                <td style="text-align: center;">{{ $rec->cuotas_totales }}</td>
                <td style="text-align: right; color: #16A34A;">{{ number_format($cobrado, 2, '.', '') }}</td>
                <td style="text-align: right; color: #DC2626; font-weight: bold;">{{ number_format($rec->saldo_restante, 2, '.', '') }}</td>
                <td style="text-align: center; font-weight: bold;">{{ strtoupper($rec->estado->value ?? $rec->estado) }}</td>
            </tr>
        @endforeach
    </tbody>
    <tfoot>
        <tr style="background-color: #E2E8F0; font-weight: bold; border-top: 2px solid #0F172A;">
            <td colspan="5" style="text-align: right; font-weight: bold;">TOTALES CARTERA (RD$):</td>
            <td style="text-align: right; font-weight: bold;">{{ number_format($totMonto, 2, '.', '') }}</td>
            <td style="text-align: right; font-weight: bold;">{{ number_format($totCuota, 2, '.', '') }}</td>
            <td colspan="2" style="text-align: center;">—</td>
            <td style="text-align: right; font-weight: bold; color: #16A34A;">{{ number_format($totCobrado, 2, '.', '') }}</td>
            <td style="text-align: right; font-weight: bold; color: #DC2626;">{{ number_format($totSaldo, 2, '.', '') }}</td>
            <td></td>
        </tr>
    </tfoot>
</table>

