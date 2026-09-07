<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Alertas CXC</title>
    <style>
        @page { margin: 35px 40px; }
        body { 
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; 
            font-size: 11px; 
            color: #334155; 
            margin: 0; 
            padding: 0; 
        }
        
        /* Filter Badges Area */
        .filters-area {
            margin-bottom: 20px;
            padding: 10px 15px;
            background-color: #f8fafc;
            border-left: 3px solid #3b82f6;
            border-radius: 4px;
        }
        .filters-area .filter-item {
            display: inline-block;
            margin-right: 20px;
            font-size: 11px;
        }
        .filters-area strong {
            color: #0f172a;
        }

        /* Table Styles */
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 25px;
        }
        th, td {
            padding: 10px 8px;
            text-align: left;
            border-bottom: 1px solid #e2e8f0;
        }
        th {
            background-color: #f1f5f9;
            color: #475569;
            font-weight: 700;
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        td {
            font-size: 11px;
            vertical-align: middle;
        }
        tbody tr:nth-child(even) {
            background-color: #f8fafc;
        }
        
        /* Badges */
        .badge {
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 9px;
            font-weight: bold;
            display: inline-block;
            text-transform: uppercase;
        }
        .badge-pago { background: #dcfce7; color: #166534; }
        .badge-nota { background: #f3e8ff; color: #6b21a8; }
        .badge-info { background: #e0f2fe; color: #0369a1; }
        .badge-warning { background: #fef9c3; color: #854d0e; }

        /* Emphasized Text */
        .fw-bold { font-weight: bold; color: #0f172a; }
        .text-right { text-align: right; }
        .text-center { text-align: center; }

        /* Totals Bar */
        .totales-container {
            width: 100%;
            display: table;
            margin-top: 20px;
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            background-color: #ffffff;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }
        .total-box {
            display: table-cell;
            width: 33.33%;
            padding: 15px;
            text-align: center;
            border-right: 1px solid #e2e8f0;
        }
        .total-box:last-child {
            border-right: none;
        }
        .total-title {
            font-size: 10px;
            color: #64748b;
            text-transform: uppercase;
            font-weight: bold;
            margin-bottom: 5px;
            letter-spacing: 0.5px;
        }
        .total-value {
            font-size: 16px;
            font-weight: bold;
        }
        
        .val-blue { color: #2563eb; }
        .val-orange { color: #ea580c; }
        .val-green { color: #16a34a; }

        /* Footer */
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 9px;
            color: #94a3b8;
            border-top: 1px solid #e2e8f0;
            padding-top: 10px;
        }
    </style>
</head>
<body>

    <!-- COMPONENTE HEADER EMPRESARIAL -->
    <x-pdf-header title="Reporte de Alertas CXC" subtitle="Listado de notificaciones e incidencias" />

    <!-- FILTROS -->
    <div class="filters-area">
        <div class="filter-item">
            <strong>Estado:</strong> {{ strtoupper($estado) }}
        </div>
        @if(request()->has('vendedor_id'))
        <div class="filter-item">
            <strong>Vendedor ID:</strong> {{ request()->vendedor_id }}
        </div>
        @endif
        @if(request()->has('cliente_id'))
        <div class="filter-item">
            <strong>Cliente ID:</strong> {{ request()->cliente_id }}
        </div>
        @endif
    </div>

    <!-- DATA TABLE -->
    <table>
        <thead>
            <tr>
                <th width="12%">Fecha</th>
                <th width="20%">Cliente</th>
                <th width="13%">Concepto</th>
                <th width="12%">Factura / Doc.</th>
                <th width="13%" class="text-right">M. Pendiente</th>
                <th width="13%" class="text-right">M. Informado</th>
                <th width="17%">Nota</th>
            </tr>
        </thead>
        <tbody>
            @forelse($alertas as $alerta)
                <tr>
                    <td>{{ $alerta->created_at->format('d/m/Y') }}</td>
                    <td class="fw-bold">{{ $alerta->cxc->cliente->nombre ?? 'Sin Cliente' }}</td>
                    <td>
                        @if($alerta->tipo == 'pago_recibido')
                            <span class="badge badge-pago">Pago</span>
                        @elseif(in_array($alerta->tipo, ['credito', 'debito', 'devolucion', 'retencion']))
                            <span class="badge badge-nota">{{ str_replace('_', ' ', $alerta->tipo) }}</span>
                        @else
                            <span class="badge badge-info">{{ str_replace('_', ' ', $alerta->tipo) }}</span>
                        @endif
                    </td>
                    <td class="fw-bold" style="color: #475569;">
                        {{ $alerta->cxc->no_factura ?? $alerta->cxc->documento ?? '-' }}
                    </td>
                    <td class="text-right" style="color:#ea580c; font-weight:bold;">
                        ${{ number_format($alerta->cxc->monto_pendiente ?? 0, 2) }}
                    </td>
                    <td class="text-right val-green">
                        ${{ number_format($alerta->monto_informado ?? 0, 2) }}
                    </td>
                    <td style="font-size:9px; color:#64748b;">
                        {{ \Illuminate\Support\Str::limit($alerta->nota, 50, '...') }}
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="7" class="text-center" style="padding: 30px; color: #94a3b8;">
                        No se encontraron alertas para los filtros seleccionados.
                    </td>
                </tr>
            @endforelse
        </tbody>
    </table>

    <!-- TOTALES -->
    <div class="totales-container">
        <div class="total-box">
            <div class="total-title">Total Monto Informado</div>
            <div class="total-value val-blue">
                ${{ number_format($totalInformado, 2) }}
            </div>
        </div>
        <div class="total-box">
            <div class="total-title">Total Pendiente (Global)</div>
            <div class="total-value val-orange">
                ${{ number_format($totalPendiente, 2) }}
            </div>
        </div>
        <div class="total-box">
            <div class="total-title">Monto Real (Balance)</div>
            <div class="total-value val-green">
                ${{ number_format($montoReal, 2) }}
            </div>
        </div>
    </div>

    <!-- FOOTER -->
    <div class="footer">
        Industria California S.R.L. - Sistema de Cuentas por Cobrar (CXC)<br>
        Documento generado automáticamente y de uso exclusivo interno.
    </div>

</body>
</html>
