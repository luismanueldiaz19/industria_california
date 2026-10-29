<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte General de Nómina - {{ $nomina->codigo }}</title>
    <style>
        @page {
            size: letter landscape;
            margin: 10mm 12mm;
        }

        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            font-size: 10px;
            color: #000000;
            background-color: #F8FAFC;
            margin: 0;
            padding: 0;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
        }

        .no-print {
            background-color: #1E293B;
            color: #FFFFFF;
            padding: 10px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            position: sticky;
            top: 0;
            z-index: 9999;
            box-shadow: 0 2px 4px rgba(0,0,0,0.15);
        }

        .no-print .btn {
            background-color: #0F172A;
            color: #FFFFFF;
            border: 1px solid #475569;
            padding: 7px 14px;
            border-radius: 6px;
            font-size: 11.5px;
            font-weight: bold;
            cursor: pointer;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            margin-left: 8px;
        }

        .no-print .btn:hover {
            background-color: #000000;
            border-color: #94A3B8;
        }

        .page-container {
            max-width: 1060px;
            margin: 15px auto;
            background: #FFFFFF;
            padding: 20px;
            border: 1.5px solid #000000;
            border-radius: 6px;
        }

        .report-header {
            display: table;
            width: 100%;
            border-bottom: 2px solid #000000;
            padding-bottom: 12px;
            margin-bottom: 14px;
        }

        .header-left {
            display: table-cell;
            width: 60%;
            vertical-align: middle;
        }

        .header-right {
            display: table-cell;
            width: 40%;
            vertical-align: middle;
            text-align: right;
        }

        .company-title {
            font-size: 16px;
            font-weight: 800;
            color: #000000;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin: 0;
        }

        .company-sub {
            font-size: 9.5px;
            color: #475569;
            margin: 2px 0 0 0;
        }

        .doc-title {
            font-size: 14px;
            font-weight: 800;
            color: #000000;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin: 0 0 4px 0;
        }

        .doc-meta {
            font-size: 9.5px;
            color: #1E293B;
            line-height: 1.35;
        }

        .summary-bar {
            display: table;
            width: 100%;
            margin-bottom: 16px;
            border-collapse: separate;
            border-spacing: 8px 0;
        }

        .summary-card {
            display: table-cell;
            width: 20%;
            background: #F8FAFC;
            border: 1px solid #94A3B8;
            border-radius: 5px;
            padding: 8px 10px;
            text-align: center;
        }

        .summary-label {
            font-size: 8.5px;
            font-weight: 700;
            color: #475569;
            text-transform: uppercase;
            margin-bottom: 4px;
        }

        .summary-amount {
            font-size: 12.5px;
            font-weight: 800;
            color: #000000;
        }

        .report-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 9px;
            margin-bottom: 20px;
        }

        .report-table th {
            background-color: #E2E8F0;
            color: #000000;
            border: 1px solid #64748B;
            padding: 6px 4px;
            font-weight: 800;
            text-align: center;
            font-size: 8.5px;
            text-transform: uppercase;
            letter-spacing: 0.3px;
        }

        .report-table td {
            border: 1px solid #E2E8F0;
            padding: 5px 4px;
            color: #000000;
        }

        .report-table tr:nth-child(even) td {
            background-color: #F8FAFC;
        }

        .report-table tfoot td {
            background-color: #E2E8F0;
            border: 1.5px solid #000000;
            font-weight: 800;
            color: #000000;
            padding: 6px 4px;
        }

        .firmas-container {
            display: table;
            width: 100%;
            margin-top: 25px;
            page-break-inside: avoid;
        }

        .firma-box {
            display: table-cell;
            width: 33.33%;
            text-align: center;
            vertical-align: top;
            padding: 0 15px;
        }

        .firma-line {
            border-top: 1px solid #000000;
            width: 85%;
            margin: 0 auto 5px auto;
        }

        .firma-role {
            font-size: 9px;
            font-weight: 800;
            color: #000000;
            text-transform: uppercase;
        }

        .firma-desc {
            font-size: 8px;
            color: #475569;
            margin-top: 2px;
        }

        @media print {
            body {
                background: #FFFFFF !important;
                color: #000000 !important;
            }
            .no-print {
                display: none !important;
            }
            .page-container {
                max-width: 100% !important;
                margin: 0 !important;
                padding: 0 !important;
                border: none !important;
            }
            .report-table th {
                background-color: #E2E8F0 !important;
                color: #000000 !important;
            }
            .report-table tfoot td {
                background-color: #E2E8F0 !important;
                color: #000000 !important;
            }
        }
    </style>
</head>
<body>

    @if(($modo ?? 'blade') !== 'pdf')
        <!-- Barra de acciones superior para vista en navegador -->
        <div class="no-print">
            <div>
                <strong style="font-size: 13px;">Reporte General de Nómina — {{ $nomina->codigo }}</strong>
                <span style="font-size: 11px; color: #94A3B8; margin-left: 8px;">({{ count($nomina->detalles) }} colaboradores procesados)</span>
            </div>
            <div>
                <button class="btn" onclick="window.print()">Imprimir Reporte</button>
                @if(!empty($urlPdf))
                    <a href="{{ $urlPdf }}" class="btn">Descargar PDF</a>
                @endif
                @if(!empty($urlExcel))
                    <a href="{{ $urlExcel }}" class="btn">Exportar Excel</a>
                @endif
                @if(!empty($urlVolantes))
                    <a href="{{ $urlVolantes }}" class="btn">Ver Volantes de Pago</a>
                @endif
            </div>
        </div>
    @endif

    <div class="page-container">
        <!-- Encabezado Institucional -->
        <div class="report-header">
            <div class="header-left">
                <h1 class="company-title">Industria California, SRL</h1>
                <p class="company-sub">RNC: 132839935 | Calle 16 Agosto #91, Moca, Rep. Dom. | Tel: 829-477-8000</p>
                <div style="margin-top: 4px; font-size: 9px; color: #475569;">
                    <strong>Tipo:</strong> Nómina {{ strtoupper($nomina->tipo_periodo->value ?? $nomina->tipo_periodo) }} &nbsp;|&nbsp;
                    <strong>Estado:</strong> <span style="background-color: #F1F5F9; color: #000000; border: 1px solid #000000; font-weight: bold; padding: 1px 5px; border-radius: 3px;">{{ strtoupper($nomina->estado->value ?? $nomina->estado) }}</span>
                </div>
            </div>
            <div class="header-right">
                <div class="doc-title">Reporte General de Nómina</div>
                <div class="doc-meta">
                    <strong>Código:</strong> {{ $nomina->codigo }}<br>
                    <strong>Periodo:</strong> Del {{ $fechaInicio }} al {{ $fechaFin }}<br>
                    <strong>Fecha de Pago:</strong> {{ $fechaPago }}
                </div>
            </div>
        </div>

        @php
            $totSalarioMensual = 0;
            $totSalarioPeriodo = 0;
            $totIngresos = 0;
            $totAfp = 0;
            $totArs = 0;
            $totIsr = 0;
            $totPrestamos = 0;
            $totDeducciones = 0;
            $totNeto = 0;

            foreach($nomina->detalles as $d) {
                $totSalarioMensual += $d->salario_mensual;
                $totSalarioPeriodo += $d->salario_periodo;
                $totIngresos += $d->total_ingresos;
                $totDeducciones += $d->total_deducciones;
                $totNeto += $d->neto_pagar;

                foreach($d->conceptos as $c) {
                    if (($c->tipo->value ?? $c->tipo) === 'deduccion') {
                        $cod = $c->concepto?->codigo ?? '';
                        if ($cod === 'AFP_EMP') $totAfp += $c->monto;
                        elseif ($cod === 'ARS_EMP') $totArs += $c->monto;
                        elseif ($cod === 'RET_ISR') $totIsr += $c->monto;
                        else $totPrestamos += $c->monto;
                    }
                }
            }
        @endphp

        <!-- Resumen de Cuadre Superior Monocromático -->
        <div class="summary-bar">
            <div class="summary-card">
                <div class="summary-label">Masa Salarial (Ingresos)</div>
                <div class="summary-amount">RD$ {{ number_format($totIngresos, 2) }}</div>
            </div>
            <div class="summary-card">
                <div class="summary-label">Retenciones TSS (AFP+ARS)</div>
                <div class="summary-amount">RD$ {{ number_format($totAfp + $totArs, 2) }}</div>
            </div>
            <div class="summary-card">
                <div class="summary-label">Retención ISR DGII</div>
                <div class="summary-amount">RD$ {{ number_format($totIsr, 2) }}</div>
            </div>
            <div class="summary-card">
                <div class="summary-label">Préstamos / Descuentos</div>
                <div class="summary-amount">RD$ {{ number_format($totPrestamos, 2) }}</div>
            </div>
            <div class="summary-card" style="background-color: #F8FAFC; border: 1.5px solid #000000;">
                <div class="summary-label" style="color: #000000; font-weight: 800;">Total Neto a Desembolsar</div>
                <div class="summary-amount" style="font-size: 13.5px; font-weight: 800;">RD$ {{ number_format($totNeto, 2) }}</div>
            </div>
        </div>

        <!-- Tabla Detallada -->
        <table class="report-table">
            <thead>
                <tr>
                    <th style="width: 25px;">#</th>
                    <th style="width: 75px;">CÉDULA</th>
                    <th style="text-align: left; width: 140px;">COLABORADOR</th>
                    <th style="text-align: left; width: 90px;">CARGO</th>
                    <th style="text-align: right; width: 65px;">SALARIO MES</th>
                    <th style="text-align: right; width: 65px;">SUELDO BASE</th>
                    <th style="text-align: right; width: 70px;">TOTAL INGRESOS</th>
                    <th style="text-align: right; width: 55px;">AFP</th>
                    <th style="text-align: right; width: 55px;">ARS</th>
                    <th style="text-align: right; width: 60px;">ISR</th>
                    <th style="text-align: right; width: 65px;">PRÉSTAMOS</th>
                    <th style="text-align: right; width: 70px;">TOTAL DEDUC.</th>
                    <th style="text-align: right; width: 75px;">NETO A PAGAR</th>
                    <th style="text-align: center; width: 80px;">FIRMA</th>
                </tr>
            </thead>
            <tbody>
                @foreach($nomina->detalles as $idx => $det)
                    @php
                        $emp = $det->empleado;
                        $afp = 0; $ars = 0; $isr = 0; $pres = 0;
                        foreach($det->conceptos as $c) {
                            if (($c->tipo->value ?? $c->tipo) === 'deduccion') {
                                $cod = $c->concepto?->codigo ?? '';
                                if ($cod === 'AFP_EMP') $afp += $c->monto;
                                elseif ($cod === 'ARS_EMP') $ars += $c->monto;
                                elseif ($cod === 'RET_ISR') $isr += $c->monto;
                                else $pres += $c->monto;
                            }
                        }
                    @endphp
                    <tr>
                        <td style="text-align: center;">{{ $idx + 1 }}</td>
                        <td style="text-align: center;">{{ $emp?->cedula ?? '—' }}</td>
                        <td style="text-align: left; font-weight: bold;">{{ $emp?->nombre_completo ?? '—' }}</td>
                        <td style="text-align: left; color: #475569;">{{ $emp?->ocupacion ?? '—' }}</td>
                        <td style="text-align: right;">{{ number_format($det->salario_mensual, 2) }}</td>
                        <td style="text-align: right;">{{ number_format($det->salario_periodo, 2) }}</td>
                        <td style="text-align: right; font-weight: 700;">{{ number_format($det->total_ingresos, 2) }}</td>
                        <td style="text-align: right;">{{ number_format($afp, 2) }}</td>
                        <td style="text-align: right;">{{ number_format($ars, 2) }}</td>
                        <td style="text-align: right;">{{ number_format($isr, 2) }}</td>
                        <td style="text-align: right;">{{ number_format($pres, 2) }}</td>
                        <td style="text-align: right; font-weight: 700;">{{ number_format($det->total_deducciones, 2) }}</td>
                        <td style="text-align: right; font-weight: 800;">{{ number_format($det->neto_pagar, 2) }}</td>
                        <td style="text-align: center; border-bottom: 1px dotted #94A3B8;">&nbsp;</td>
                    </tr>
                @endforeach
            </tbody>
            <tfoot>
                <tr>
                    <td colspan="4" style="text-align: right; font-weight: bold;">TOTALES GENERALES:</td>
                    <td style="text-align: right;">{{ number_format($totSalarioMensual, 2) }}</td>
                    <td style="text-align: right;">{{ number_format($totSalarioPeriodo, 2) }}</td>
                    <td style="text-align: right;">RD$ {{ number_format($totIngresos, 2) }}</td>
                    <td style="text-align: right;">{{ number_format($totAfp, 2) }}</td>
                    <td style="text-align: right;">{{ number_format($totArs, 2) }}</td>
                    <td style="text-align: right;">{{ number_format($totIsr, 2) }}</td>
                    <td style="text-align: right;">{{ number_format($totPrestamos, 2) }}</td>
                    <td style="text-align: right;">RD$ {{ number_format($totDeducciones, 2) }}</td>
                    <td style="text-align: right;">RD$ {{ number_format($totNeto, 2) }}</td>
                    <td></td>
                </tr>
            </tfoot>
        </table>

        <!-- Firmas Institucionales -->
        <div class="firmas-container">
            <div class="firma-box">
                <div class="firma-line"></div>
                <div class="firma-role">ELABORADO POR</div>
                <div class="firma-desc">Encargado de Nómina / RRHH</div>
            </div>
            <div class="firma-box">
                <div class="firma-line"></div>
                <div class="firma-role">REVISADO POR</div>
                <div class="firma-desc">Contabilidad / Auditoría Interna</div>
            </div>
            <div class="firma-box">
                <div class="firma-line"></div>
                <div class="firma-role">AUTORIZADO POR</div>
                <div class="firma-desc">Gerencia General / Dirección Financiera</div>
            </div>
        </div>
    </div>

</body>
</html>
