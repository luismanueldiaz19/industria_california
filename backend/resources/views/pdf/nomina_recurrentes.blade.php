<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte de Préstamos y Descuentos Recurrentes</title>
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

        .report-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 9.5px;
            margin-bottom: 20px;
        }

        .report-table th {
            background-color: #E2E8F0;
            color: #000000;
            border: 1px solid #64748B;
            padding: 6px 6px;
            font-weight: 800;
            text-align: center;
            font-size: 9px;
            text-transform: uppercase;
            letter-spacing: 0.3px;
        }

        .report-table td {
            border: 1px solid #E2E8F0;
            padding: 6px 6px;
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
            padding: 6px 6px;
        }

        .badge-estado {
            display: inline-block;
            padding: 2px 6px;
            border-radius: 3px;
            font-size: 8.5px;
            font-weight: 800;
            text-transform: uppercase;
            background-color: #F1F5F9;
            color: #000000;
            border: 1px solid #000000;
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
        }
    </style>
</head>
<body>

    @if(($modo ?? 'blade') !== 'pdf')
        <div class="no-print">
            <div>
                <strong style="font-size: 13px;">Cartera de Préstamos y Deducciones Recurrentes</strong>
                <span style="font-size: 11px; color: #94A3B8; margin-left: 8px;">({{ count($recurrentes) }} registros)</span>
            </div>
            <div>
                <button class="btn" onclick="window.print()">Imprimir Reporte</button>
                @if(!empty($urlPdf))
                    <a href="{{ $urlPdf }}" class="btn">Descargar PDF</a>
                @endif
                @if(!empty($urlExcel))
                    <a href="{{ $urlExcel }}" class="btn">Exportar Excel</a>
                @endif
            </div>
        </div>
    @endif

    <div class="page-container">
        <div class="report-header">
            <div class="header-left">
                <h1 class="company-title">Industria California, SRL</h1>
                <p class="company-sub">RNC: 132839935 | Calle 16 Agosto #91, Moca, Rep. Dom. | Tel: 829-477-8000</p>
                <div style="margin-top: 4px; font-size: 9px; color: #475569;">
                    Control y Amortización Automática de Cuotas por Periodo
                </div>
            </div>
            <div class="header-right">
                <div class="doc-title">Reporte de Cartera Recurrente</div>
                <div class="doc-meta">
                    <strong>Fecha Emisión:</strong> {{ date('d/m/Y h:i A') }}<br>
                    <strong>Tipo:</strong> Préstamos, Ahorros y Descuentos Fijos
                </div>
            </div>
        </div>

        @php
            $totOriginal = 0;
            $totCuota = 0;
            $totSaldo = 0;
            foreach($recurrentes as $r) {
                $totOriginal += $r->monto_total;
                $totCuota += $r->monto_cuota;
                $totSaldo += $r->saldo_pendiente;
            }
        @endphp

        <table class="report-table">
            <thead>
                <tr>
                    <th style="width: 30px;">#</th>
                    <th style="width: 85px;">CÉDULA</th>
                    <th style="text-align: left; width: 180px;">COLABORADOR</th>
                    <th style="text-align: left; width: 130px;">CONCEPTO</th>
                    <th style="text-align: left;">DESCRIPCIÓN</th>
                    <th style="text-align: right; width: 85px;">TOTAL ORIGINAL</th>
                    <th style="text-align: right; width: 80px;">CUOTA / PER.</th>
                    <th style="text-align: center; width: 65px;">CUOTAS</th>
                    <th style="text-align: right; width: 85px;">SALDO RESTANTE</th>
                    <th style="text-align: center; width: 70px;">ESTADO</th>
                </tr>
            </thead>
            <tbody>
                @forelse($recurrentes as $idx => $rec)
                    <tr>
                        <td style="text-align: center;">{{ $idx + 1 }}</td>
                        <td style="text-align: center;">{{ $rec->empleado?->cedula ?? '—' }}</td>
                        <td style="text-align: left; font-weight: bold;">{{ $rec->empleado?->nombre_completo ?? '—' }}</td>
                        <td style="text-align: left;">{{ $rec->concepto?->nombre ?? 'Préstamo' }}</td>
                        <td style="text-align: left; color: #475569;">{{ $rec->descripcion ?? '—' }}</td>
                        <td style="text-align: right;">{{ number_format($rec->monto_total, 2) }}</td>
                        <td style="text-align: right; font-weight: 700;">{{ number_format($rec->monto_cuota, 2) }}</td>
                        <td style="text-align: center; font-family: monospace;">{{ $rec->cuotas_descontadas }}/{{ $rec->cuotas_totales }}</td>
                        <td style="text-align: right; font-weight: 800;">{{ number_format($rec->saldo_pendiente, 2) }}</td>
                        <td style="text-align: center;">
                            <span class="badge-estado">{{ $rec->activo ? 'ACTIVO' : 'SALDADO' }}</span>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="10" style="text-align: center; color: #64748B; padding: 15px;">No hay deducciones recurrentes registradas.</td>
                    </tr>
                @endforelse
            </tbody>
            <tfoot>
                <tr>
                    <td colspan="5" style="text-align: right; font-weight: bold;">TOTALES EN CARTERA:</td>
                    <td style="text-align: right;">RD$ {{ number_format($totOriginal, 2) }}</td>
                    <td style="text-align: right;">RD$ {{ number_format($totCuota, 2) }}</td>
                    <td></td>
                    <td style="text-align: right;">RD$ {{ number_format($totSaldo, 2) }}</td>
                    <td></td>
                </tr>
            </tfoot>
        </table>
    </div>

</body>
</html>
