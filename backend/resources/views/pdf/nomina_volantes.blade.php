<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Volantes de Pago - {{ $nomina->codigo }}</title>
    <style>
        @page {
            size: letter portrait;
            margin: 8mm 12mm;
        }

        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            font-size: 10.5px;
            color: #000000;
            background-color: #F8FAFC;
            margin: 0;
            padding: 0;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
        }

        /* ── Barra de Herramientas Web (Solo visible en navegador) ── */
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

        .volantes-wrapper {
            max-width: 800px;
            margin: 15px auto;
        }

        /* ── Tarjeta de Volante Monocromática (2 por Hoja Carta) ── */
        .volante-card {
            background: #FFFFFF;
            border: 1.5px solid #000000;
            border-radius: 6px;
            padding: 12px 16px;
            margin-bottom: 12px;
            box-sizing: border-box;
            page-break-inside: avoid;
        }

        .page-break {
            page-break-after: always;
            height: 0;
            line-height: 0;
            margin: 0;
            padding: 0;
        }

        /* ── Encabezado Institucional ── */
        .volante-header {
            display: table;
            width: 100%;
            border-bottom: 2px solid #000000;
            padding-bottom: 10px;
            margin-bottom: 12px;
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
            font-size: 15px;
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

        .doc-badge {
            display: inline-block;
            background-color: #F1F5F9;
            color: #000000;
            border: 1.5px solid #000000;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 4px;
        }

        .periodo-meta {
            font-size: 9.5px;
            color: #1E293B;
            line-height: 1.35;
        }

        /* ── Cuadro de Información del Colaborador ── */
        .colaborador-box {
            background-color: #F8FAFC;
            border: 1px solid #94A3B8;
            border-radius: 5px;
            padding: 8px 12px;
            margin-bottom: 14px;
            display: table;
            width: 100%;
            box-sizing: border-box;
        }

        .colaborador-col {
            display: table-cell;
            vertical-align: top;
            width: 50%;
        }

        .info-row {
            margin-bottom: 3px;
            font-size: 10px;
        }

        .info-label {
            color: #475569;
            font-weight: 700;
            display: inline-block;
            width: 95px;
        }

        .info-value {
            color: #000000;
            font-weight: 700;
        }

        /* ── Tablas de Ingresos y Deducciones ── */
        .tablas-split {
            display: table;
            width: 100%;
            margin-bottom: 12px;
            border-collapse: separate;
            border-spacing: 10px 0;
        }

        .tabla-seccion {
            display: table-cell;
            width: 50%;
            vertical-align: top;
            background: #FFFFFF;
            border: 1px solid #64748B;
            border-radius: 5px;
            padding: 0;
            overflow: hidden;
        }

        .tabla-seccion table {
            width: 100%;
            border-collapse: collapse;
        }

        .tabla-seccion th {
            padding: 6px 10px;
            font-size: 10px;
            font-weight: 800;
            text-align: left;
            background-color: #E2E8F0;
            color: #000000;
            border-bottom: 1.5px solid #64748B;
            letter-spacing: 0.3px;
        }

        .tabla-seccion td {
            padding: 5px 10px;
            font-size: 10px;
            color: #000000;
            border-bottom: 1px solid #E2E8F0;
        }

        .subtotal-row {
            background-color: #F1F5F9;
            font-weight: 800;
            color: #000000;
            border-top: 1.5px solid #64748B;
        }

        .subtotal-row td {
            font-weight: 800;
            color: #000000;
            border-bottom: none;
        }

        /* ── Bloque Neto Destacado (Monocromático) ── */
        .neto-box {
            background-color: #F8FAFC;
            border: 2px solid #000000;
            border-radius: 5px;
            padding: 9px 14px;
            display: table;
            width: 100%;
            box-sizing: border-box;
            margin-bottom: 20px;
        }

        .neto-left {
            display: table-cell;
            vertical-align: middle;
            font-size: 11px;
            font-weight: 800;
            color: #000000;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .neto-right {
            display: table-cell;
            vertical-align: middle;
            text-align: right;
            font-size: 15px;
            font-weight: 800;
            color: #000000;
        }

        /* ── Bloque de Firmas ── */
        .firmas-row {
            display: table;
            width: 100%;
            margin-top: 22px;
            padding-top: 8px;
        }

        .firma-col {
            display: table-cell;
            width: 46%;
            text-align: center;
            vertical-align: top;
        }

        .firma-line {
            border-top: 1px solid #000000;
            width: 80%;
            margin: 0 auto 5px auto;
        }

        .firma-text {
            font-size: 9px;
            color: #1E293B;
            line-height: 1.35;
        }

        /* ── Separador entre volantes en vista web ── */
        .corte-line {
            text-align: center;
            color: #64748B;
            font-size: 10px;
            font-weight: bold;
            margin: 14px 0 22px 0;
            border-bottom: 1px dashed #94A3B8;
            line-height: 0.1em;
        }

        .corte-line span {
            background: #F8FAFC;
            padding: 0 10px;
        }

        @media print {
            body {
                background: #FFFFFF !important;
                font-size: 9.5px;
                color: #000000 !important;
            }
            .no-print {
                display: none !important;
            }
            .volantes-wrapper {
                max-width: 100% !important;
                margin: 0 !important;
            }
            .volante-card {
                border: 1.5px solid #000000 !important;
                box-shadow: none !important;
                margin-bottom: 8px !important;
                padding: 10px 14px !important;
                page-break-inside: avoid !important;
            }
            .tabla-seccion th {
                background-color: #E2E8F0 !important;
                color: #000000 !important;
            }
            .neto-box {
                border: 2px solid #000000 !important;
                background-color: #F8FAFC !important;
                margin-bottom: 12px !important;
                padding: 6px 12px !important;
            }
            .firmas-row {
                margin-top: 14px !important;
            }
            .corte-line {
                display: block !important;
                margin: 8px 0 12px 0 !important;
            }
            .page-break {
                page-break-after: always !important;
            }
        }
    </style>
</head>
<body>

    @if(($modo ?? 'blade') !== 'pdf')
        <!-- Barra de acciones superior para vista en navegador -->
        <div class="no-print">
            <div>
                <strong style="font-size: 13px;">Volantes de Nómina — {{ $nomina->codigo }}</strong>
                <span style="font-size: 11px; color: #94A3B8; margin-left: 8px;">({{ count($detalles) }} colaboradores)</span>
            </div>
            <div>
                <button class="btn" onclick="window.print()">Imprimir Volantes</button>
                @if(!empty($urlPdf))
                    <a href="{{ $urlPdf }}" class="btn">Descargar PDF</a>
                @endif
                @if(!empty($urlExcel))
                    <a href="{{ $urlExcel }}" class="btn">Exportar Excel</a>
                @endif
            </div>
        </div>
    @endif

    <div class="volantes-wrapper">
        @foreach($detalles as $det)
            @php
                $emp = $det->empleado;

                // Separar conceptos en ingresos y deducciones
                $ingresos = [];
                $deducciones = [];

                foreach($det->conceptos as $c) {
                    $tipo = $c->tipo->value ?? $c->tipo;
                    if ($tipo === 'ingreso') {
                        $ingresos[] = $c;
                    } else {
                        $deducciones[] = $c;
                    }
                }
            @endphp

            <div class="volante-card">
                <!-- Encabezado del Volante -->
                <div class="volante-header">
                    <div class="header-left">
                        <h1 class="company-title">Industria California, SRL</h1>
                        <p class="company-sub">RNC: 132839935 | Calle 16 Agosto #91, Moca, Rep. Dom. | Tel: 829-477-8000</p>
                    </div>
                    <div class="header-right">
                        <div class="doc-badge">Volante de Pago</div>
                        <div class="periodo-meta">
                            <strong>{{ $nomina->codigo }}</strong> — {{ $nomina->titulo }}<br>
                            Periodo: {{ $fechaInicio }} al {{ $fechaFin }} | Pago: {{ $fechaPago }}
                        </div>
                    </div>
                </div>

                <!-- Datos del Colaborador -->
                <div class="colaborador-box">
                    <div class="colaborador-col">
                        <div class="info-row">
                            <span class="info-label">COLABORADOR:</span>
                            <span class="info-value">{{ $emp?->nombre_completo ?? '—' }}</span>
                        </div>
                        <div class="info-row">
                            <span class="info-label">CÉDULA:</span>
                            <span class="info-value">{{ $emp?->cedula ?? '—' }}</span>
                        </div>
                        <div class="info-row">
                            <span class="info-label">DEPARTAMENTO:</span>
                            <span class="info-value">{{ $emp?->departamento ?? 'Operaciones' }}</span>
                        </div>
                    </div>
                    <div class="colaborador-col">
                        <div class="info-row">
                            <span class="info-label">CARGO:</span>
                            <span class="info-value">{{ $emp?->ocupacion ?? 'Empleado' }}</span>
                        </div>
                        <div class="info-row">
                            <span class="info-label">SALARIO MES:</span>
                            <span class="info-value">---------</span>
                        </div>
                        <div class="info-row">
                            <span class="info-label">TIPO PAGO:</span>
                            <span class="info-value">{{ strtoupper($nomina->tipo_periodo->value ?? $nomina->tipo_periodo) }}</span>
                        </div>
                    </div>
                </div>

                <!-- Tablas en Paralelo: Ingresos vs Deducciones -->
                <div class="tablas-split">
                    <!-- Columna de Ingresos -->
                    <div class="tabla-seccion">
                        <table>
                            <thead>
                                <tr>
                                    <th>INGRESOS / HABERES</th>
                                    <th style="text-align: right;">MONTO (RD$)</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td>Salario Ordinario Periodo</td>
                                    <td style="text-align: right; font-weight: 700;">{{ number_format($det->salario_periodo, 2) }}</td>
                                </tr>
                                @foreach($ingresos as $ing)
                                    @if(!in_array($ing->concepto?->codigo ?? '', ['SALARIO_ORDINARIO', 'SALARIO_QUINCENAL', 'SALARIO_MENSUAL', 'SALARIO_BASE']))
                                        <tr>
                                            <td>{{ $ing->concepto?->nombre ?? 'Ingreso Adicional' }}</td>
                                            <td style="text-align: right;">{{ number_format($ing->monto, 2) }}</td>
                                        </tr>
                                    @endif
                                @endforeach
                            </tbody>
                            <tfoot>
                                <tr class="subtotal-row">
                                    <td>TOTAL INGRESOS:</td>
                                    <td style="text-align: right;">RD$ {{ number_format($det->total_ingresos, 2) }}</td>
                                </tr>
                            </tfoot>
                        </table>
                    </div>

                    <!-- Columna de Deducciones -->
                    <div class="tabla-seccion">
                        <table>
                            <thead>
                                <tr>
                                    <th>DEDUCCIONES / RETENCIONES</th>
                                    <th style="text-align: right;">MONTO (RD$)</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($deducciones as $ded)
                                    @php
                                        $nombreDed = $ded->concepto?->nombre ?? 'Deducción';
                                        $cod = $ded->concepto?->codigo ?? '';
                                        if ($cod === 'AFP_EMP') $nombreDed = 'AFP';
                                        elseif ($cod === 'ARS_EMP') $nombreDed = 'ARS';
                                        elseif ($cod === 'RET_ISR') $nombreDed = 'ISR';

                                        if ($ded->referencia_cuota) {
                                            $nombreDed .= ' (' . $ded->referencia_cuota . ')';
                                        }
                                    @endphp
                                    <tr>
                                        <td>{{ $nombreDed }}</td>
                                        <td style="text-align: right;">{{ number_format($ded->monto, 2) }}</td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="2" style="text-align: center; color: #64748B; padding: 10px;">Sin deducciones aplicadas</td>
                                    </tr>
                                @endforelse
                            </tbody>
                            <tfoot>
                                <tr class="subtotal-row">
                                    <td>TOTAL DEDUCCIONES:</td>
                                    <td style="text-align: right;">RD$ {{ number_format($det->total_deducciones, 2) }}</td>
                                </tr>
                            </tfoot>
                        </table>
                    </div>
                </div>

                <!-- Recuadro Resaltado de Neto a Pagar -->
                <div class="neto-box">
                    <div class="neto-left">
                        TOTAL NETO:
                    </div>
                    <div class="neto-right">
                        RD$ {{ number_format($det->neto_pagar, 2) }}
                    </div>
                </div>

                <!-- Bloque de Firmas -->
                <div class="firmas-row">
                    <div class="firma-col">
                        <div class="firma-line"></div>
                        <div class="firma-text">
                            <strong>ENTREGADO POR</strong><br>
                            Recursos Humanos / Nómina
                        </div>
                    </div>
                    <div style="display: table-cell; width: 8%;"></div>
                    <div class="firma-col">
                        <div class="firma-line"></div>
                        <div class="firma-text">
                            <strong>RECIBIDO CONFORME</strong><br>
                            {{ $emp?->nombre_completo ?? 'Firma del Colaborador' }}<br>
                            Cédula: {{ $emp?->cedula ?? '___________' }}
                        </div>
                    </div>
                </div>
            </div>

            @if(!$loop->last)
                @if($loop->iteration % 2 == 0)
                    <div class="page-break"></div>
                @else
                    <div class="corte-line"><span>✂ - - - - - - CORTAR AQUÍ - - - - - - ✂</span></div>
                @endif
            @endif
        @endforeach
    </div>

</body>
</html>
