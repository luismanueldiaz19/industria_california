<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Pedidos por Vendedor</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: Arial, sans-serif;
            font-size: 10px;
            color: #1e293b;
            background: #fff;
        }
        .container {
            width: 100%;
            max-width: 1000px;
            margin: 0 auto;
            padding: 20px;
        }

        /* â”€â”€ Filtros aplicados â”€â”€ */
        .filtros-bar {
            background: #f1f5f9;
            border: 1px solid #e2e8f0;
            border-radius: 4px;
            padding: 6px 12px;
            margin-bottom: 18px;
            font-size: 9px;
            color: #475569;
        }
        .filtros-bar span { margin-right: 18px; }
        .filtros-bar strong { color: #1e293b; }

        /* â”€â”€ Resumen superior â”€â”€ */
        .summary-grid {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        .summary-grid td {
            width: 33.33%;
            padding: 10px 14px;
            text-align: center;
            background: #f8fafc;
            border: 1px solid #e2e8f0;
        }
        .summary-grid .s-val {
            font-size: 18px;
            font-weight: bold;
            color: #0f172a;
            display: block;
        }
        .summary-grid .s-lbl {
            font-size: 8px;
            text-transform: uppercase;
            letter-spacing: 0.6px;
            color: #64748b;
            margin-top: 2px;
        }

        /* â”€â”€ Bloque por vendedor â”€â”€ */
        .vendedor-block {
            margin-bottom: 22px;
            page-break-inside: avoid;
        }
        .vendedor-header {
            display: table;
            width: 100%;
            background: #1e2f4c;
            color: #fff;
            padding: 7px 10px;
            border-radius: 3px 3px 0 0;
        }
        .vendedor-header .vh-name {
            display: table-cell;
            font-size: 11px;
            font-weight: bold;
            letter-spacing: 0.3px;
        }
        .vendedor-header .vh-total {
            display: table-cell;
            text-align: right;
            font-size: 11px;
            font-weight: bold;
            color: #fbbf24;
        }

        /* Contador de estados */
        .estados-row {
            display: table;
            width: 100%;
            border-left: 1px solid #e2e8f0;
            border-right: 1px solid #e2e8f0;
        }
        .estado-cell {
            display: table-cell;
            text-align: center;
            padding: 5px;
            font-size: 8.5px;
            border-bottom: 1px solid #e2e8f0;
        }
        .estado-cell .e-count { font-size: 13px; font-weight: bold; display: block; }
        .e-borrador  .e-count { color: #64748b; }
        .e-enviado   .e-count { color: #3b82f6; }
        .e-facturado .e-count { color: #16a34a; }
        .e-cancelado .e-count { color: #dc2626; }

        /* Tabla de pedidos del vendedor */
        .table {
            width: 100%;
            border-collapse: collapse;
        }
        .table th {
            background: #e2e8f0;
            color: #334155;
            padding: 5px 7px;
            text-align: left;
            font-size: 8px;
            text-transform: uppercase;
            letter-spacing: 0.3px;
        }
        .table th.right, .table td.right { text-align: right; }
        .table th.center, .table td.center { text-align: center; }
        .table td {
            border-bottom: 1px solid #f1f5f9;
            padding: 5px 7px;
            font-size: 9px;
            color: #334155;
        }
        .table tr:nth-child(even) td { background: #f8fafc; }

        /* Badges de estado */
        .badge {
            display: inline-block;
            padding: 1px 6px;
            border-radius: 3px;
            font-size: 7.5px;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 0.4px;
        }
        .badge-borrador  { background: #f1f5f9; color: #64748b; }
        .badge-enviado   { background: #dbeafe; color: #1d4ed8; }
        .badge-facturado { background: #dcfce7; color: #15803d; }
        .badge-cancelado { background: #fee2e2; color: #b91c1c; }

        /* Sub-total del vendedor */
        .subtotal-row td {
            background: #f1f5f9;
            font-weight: bold;
            font-size: 9px;
            color: #0f172a;
            padding: 6px 7px;
            border-top: 1.5px solid #cbd5e1;
        }

        /* Total general */
        .grand-total-box {
            margin-top: 20px;
            text-align: right;
            border-top: 2px solid #1e2f4c;
            padding-top: 8px;
        }
        .grand-total-box .gt-label {
            font-size: 10px;
            color: #475569;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .grand-total-box .gt-amount {
            font-size: 20px;
            font-weight: bold;
            color: #1e2f4c;
        }

        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 8px;
            color: #94a3b8;
            border-top: 1px solid #e2e8f0;
            padding-top: 8px;
        }
    </style>
</head>
<body>
<div class="container">

    {{-- Header corporativo estÃ¡ndar --}}
    @include('components.pdf-header', [
        'title'    => 'Reporte de Pedidos por Vendedor',
        'subtitle' => 'PerÃ­odo: ' . ($fechaInicio ?? 'Inicio') . ' al ' . ($fechaFin ?? now()->subHours(4)->format('d/m/Y'))
    ])

    {{-- Filtros aplicados --}}
    <div class="filtros-bar">
        <span><strong>PerÃ­odo:</strong> {{ $fechaInicio ?? 'Todo' }} â€” {{ $fechaFin ?? 'Hoy' }}</span>
        <span><strong>Vendedores:</strong> {{ count($vendedores) }}</span>
        <span><strong>Generado:</strong> {{ \Carbon\Carbon::now()->subHours(4)->format('d/m/Y H:i') }}</span>
    </div>

    {{-- Resumen general --}}
    @php
        $totalGeneral      = 0;
        $totalPedidosGral  = 0;
        foreach ($vendedores as $v) {
            $totalGeneral     += $v['total_monto'];
            $totalPedidosGral += $v['total_pedidos'];
        }
    @endphp
    <table class="summary-grid">
        <tr>
            <td>
                <span class="s-val">{{ count($vendedores) }}</span>
                <span class="s-lbl">Vendedores activos</span>
            </td>
            <td>
                <span class="s-val">{{ $totalPedidosGral }}</span>
                <span class="s-lbl">Total pedidos</span>
            </td>
            <td>
                <span class="s-val">${{ number_format($totalGeneral, 2) }}</span>
                <span class="s-lbl">Monto total</span>
            </td>
        </tr>
    </table>

    {{-- Bloque por vendedor --}}
    @foreach($vendedores as $v)
    <div class="vendedor-block">
        {{-- Encabezado del vendedor --}}
        <div class="vendedor-header">
            <span class="vh-name">{{ strtoupper($v['vendedor_nombre']) }}</span>
            <span class="vh-total">${{ number_format($v['total_monto'], 2) }}</span>
        </div>

        {{-- Contadores de estado --}}
        <div class="estados-row">
            <div class="estado-cell e-borrador">
                <span class="e-count">{{ $v['borrador'] }}</span>Borrador
            </div>
            <div class="estado-cell e-enviado">
                <span class="e-count">{{ $v['enviado'] }}</span>Enviado
            </div>
            <div class="estado-cell e-facturado">
                <span class="e-count">{{ $v['facturado'] }}</span>Facturado
            </div>
            <div class="estado-cell e-cancelado">
                <span class="e-count">{{ $v['cancelado'] }}</span>Cancelado
            </div>
        </div>

        {{-- Tabla de pedidos individuales del vendedor --}}
        @if(!empty($v['pedidos']))
        <table class="table">
            <thead>
                <tr>
                    <th style="width:7%">ID</th>
                    <th style="width:15%">FECHA</th>
                    <th style="width:33%">CLIENTE</th>
                    <th style="width:15%" class="center">ESTADO</th>
                    <th style="width:30%" class="right">TOTAL</th>
                </tr>
            </thead>
            <tbody>
                @foreach($v['pedidos'] as $pedido)
                <tr>
                    <td>#{{ $pedido->id }}</td>
                    <td>{{ \Carbon\Carbon::parse($pedido->created_at)->subHours(4)->format('d/m/Y H:i') }}</td>
                    <td>{{ $pedido->cliente->nombre ?? 'N/A' }}</td>
                    <td class="center">
                        <span class="badge badge-{{ $pedido->estado }}">
                            {{ strtoupper($pedido->estado) }}
                        </span>
                    </td>
                    <td class="right">${{ number_format($pedido->total, 2) }}</td>
                </tr>
                @endforeach
                <tr class="subtotal-row">
                    <td colspan="4">Subtotal â€” {{ $v['total_pedidos'] }} pedidos</td>
                    <td class="right">${{ number_format($v['total_monto'], 2) }}</td>
                </tr>
            </tbody>
        </table>
        @endif
    </div>
    @endforeach

    {{-- Total general --}}
    <div class="grand-total-box">
        <div class="gt-label">Total General ({{ $totalPedidosGral }} pedidos)</div>
        <div class="gt-amount">${{ number_format($totalGeneral, 2) }}</div>
    </div>

    <div class="footer">
        Reporte generado automÃ¡ticamente por el Sistema de Ventas â€” Industria California, SRL
    </div>
</div>
</body>
</html>

