<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Productos Facturados Pendientes de Entrega</title>
    <style>
        @page {
            margin: 20px 25px 25px 25px;
        }
        body {
            font-family: Arial, Helvetica, sans-serif;
            font-size: 9px;
            color: #1e293b;
            background: #ffffff;
            margin: 0;
            padding: 0;
        }

        /* ── Barra de Filtros Aplicados ── */
        .filtros-bar {
            background: #f1f5f9;
            border: 1px solid #e2e8f0;
            border-radius: 3px;
            padding: 5px 10px;
            margin-bottom: 12px;
            font-size: 8.5px;
            color: #475569;
        }
        .filtros-bar span { margin-right: 14px; }
        .filtros-bar strong { color: #0f172a; }

        /* ── Resumen de KPIs Superior ── */
        .summary-grid {
            width: 100%;
            border-collapse: collapse;
            table-layout: fixed;
            margin-bottom: 14px;
        }
        .summary-grid td {
            width: 25%;
            padding: 7px 8px;
            text-align: center;
            background: #f8fafc;
            border: 1px solid #cbd5e1;
            vertical-align: middle;
        }
        .summary-grid .s-val {
            font-size: 14px;
            font-weight: bold;
            color: #1e3a8a;
            display: block;
        }
        .summary-grid .s-lbl {
            font-size: 7.5px;
            text-transform: uppercase;
            letter-spacing: 0.4px;
            color: #64748b;
            margin-top: 2px;
        }

        /* ── Bloque por Vendedor ── */
        .vendedor-block {
            margin-bottom: 14px;
            page-break-inside: avoid;
        }
        .vendedor-header-table {
            width: 100%;
            border-collapse: collapse;
            table-layout: fixed;
            background: #1e2f4c;
            border: 1px solid #1e2f4c;
        }
        .vendedor-header-table td {
            padding: 5px 8px;
            vertical-align: middle;
        }
        .vh-name {
            color: #ffffff;
            font-size: 9.5px;
            font-weight: bold;
            letter-spacing: 0.3px;
            text-align: left;
        }
        .vh-pedidos {
            font-size: 8px;
            font-weight: normal;
            color: #93c5fd;
            margin-left: 6px;
        }
        .vh-total {
            color: #fbbf24;
            font-size: 9px;
            font-weight: bold;
            text-align: right;
            width: 42%;
        }

        /* ── Tablas Principales ── */
        .table {
            width: 100%;
            border-collapse: collapse;
            table-layout: fixed;
            margin-bottom: 12px;
        }
        .table th {
            background-color: #2b3e5d;
            color: #ffffff;
            padding: 5px 6px;
            text-align: left;
            font-size: 8px;
            text-transform: uppercase;
            letter-spacing: 0.3px;
            border: 1px solid #1e2f4c;
            word-wrap: break-word;
        }
        .table td {
            border: 1px solid #e2e8f0;
            padding: 4px 6px;
            font-size: 8.5px;
            vertical-align: middle;
            word-wrap: break-word;
        }
        .table tr:nth-child(even) td {
            background-color: #f8fafc;
        }
        .table th.right, .table td.right {
            text-align: right;
        }
        .table th.center, .table td.center {
            text-align: center;
        }

        .badge-qty {
            background-color: #dbeafe;
            color: #1e40af;
            font-weight: bold;
            padding: 2px 4px;
            border-radius: 3px;
            display: inline-block;
        }
        .badge-stock-ok {
            color: #16a34a;
            font-weight: bold;
        }
        .badge-stock-low {
            color: #d97706;
            font-weight: bold;
        }
        .detalle-pedido-pill {
            display: inline-block;
            background: #ffffff;
            border: 1px solid #cbd5e1;
            border-radius: 3px;
            padding: 1px 4px;
            margin: 1px 2px;
            font-size: 7.5px;
            color: #334155;
            white-space: normal;
        }

        .footer {
            clear: both;
            margin-top: 20px;
            text-align: center;
            font-size: 8px;
            color: #64748b;
            border-top: 1px solid #e2e8f0;
            padding-top: 6px;
        }
    </style>
</head>
<body>

    <!-- Header Corporativo -->
    @include('components.pdf-header', [
        'title' => 'Productos por Entregar',
        'subtitle' => 'Facturados pendientes de despacho' . ($vista === 'producto' ? ' (Consolidado por Producto)' : ' (Por Vendedor)')
    ])

    <!-- Barra de Filtros Aplicados -->
    <div class="filtros-bar">
        <span><strong>Modo de Vista:</strong> {{ $vista === 'producto' ? 'Consolidado por Producto' : 'Agrupado por Vendedor' }}</span>
        <span><strong>Vendedor:</strong> {{ $vendedorNombre ?? 'Todos los vendedores' }}</span>
        @if(!empty($search))
            <span><strong>Búsqueda:</strong> "{{ $search }}"</span>
        @endif
        <span><strong>Generado:</strong> {{ $fechaGeneracion ?? now()->subHours(4)->format('d/m/Y h:i A') }}</span>
    </div>

    <!-- Resumen Superior de Totales -->
    <table class="summary-grid">
        <tr>
            <td>
                <span class="s-val">{{ number_format($resumen['total_unidades_pendientes'] ?? 0, 2) }}</span>
                <span class="s-lbl">Unidades Pendientes</span>
            </td>
            <td>
                <span class="s-val">RD$ {{ number_format($resumen['total_monto_pendiente'] ?? 0, 2) }}</span>
                <span class="s-lbl">Monto Facturado Pendiente</span>
            </td>
            <td>
                <span class="s-val">{{ $resumen['total_pedidos'] ?? 0 }}</span>
                <span class="s-lbl">Pedidos / Facturas</span>
            </td>
            <td>
                <span class="s-val">{{ $resumen['total_vendedores'] ?? 0 }}</span>
                <span class="s-lbl">Vendedores Activos</span>
            </td>
        </tr>
    </table>

    @if($vista === 'producto')
        <!-- ════════════ VISTA CONSOLIDADA POR PRODUCTO ════════════ -->
        <table class="table">
            <thead>
                <tr>
                    <th style="width: 10%;">CÓDIGO</th>
                    <th style="width: 30%;">DESCRIPCIÓN DEL PRODUCTO</th>
                    <th style="width: 7%;" class="center">UND</th>
                    <th style="width: 10%;" class="right">STOCK</th>
                    <th style="width: 11%;" class="right">PENDIENTE</th>
                    <th style="width: 12%;" class="right">MONTO RD$</th>
                    <th style="width: 20%;">VENDEDORES ASIGNADOS</th>
                </tr>
            </thead>
            <tbody>
                @forelse($porProducto as $prod)
                    @php
                        $stock = (float)($prod['stock_actual'] ?? 0);
                        $cant = (float)($prod['total_cantidad_pendiente'] ?? 0);
                    @endphp
                    <tr>
                        <td><strong>{{ $prod['codigo'] ?? 'N/A' }}</strong></td>
                        <td>{{ $prod['nombre_completo'] ?? $prod['descripcion'] ?? '' }}</td>
                        <td class="center">{{ $prod['unidad'] ?? 'UND' }}</td>
                        <td class="right">
                            <span class="{{ $stock >= $cant ? 'badge-stock-ok' : 'badge-stock-low' }}">
                                {{ number_format($stock, 2) }}
                            </span>
                        </td>
                        <td class="right">
                            <span class="badge-qty">{{ number_format($cant, 2) }}</span>
                        </td>
                        <td class="right">RD$ {{ number_format($prod['total_monto_pendiente'] ?? 0, 2) }}</td>
                        <td>
                            @if(!empty($prod['vendedores']))
                                @foreach($prod['vendedores'] as $v)
                                    <span class="detalle-pedido-pill">
                                        {{ $v['vendedor_nombre'] ?? 'Vend' }}: {{ number_format($v['cantidad'] ?? 0, 2) }}
                                    </span>
                                @endforeach
                            @else
                                -
                            @endif
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="7" class="center" style="padding: 15px; color: #64748b;">
                            No se encontraron productos pendientes con los filtros aplicados.
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    @else
        <!-- ════════════ VISTA AGRUPADA POR VENDEDOR ════════════ -->
        @forelse($porVendedor as $vendedor)
            <div class="vendedor-block">
                <table class="vendedor-header-table">
                    <tr>
                        <td class="vh-name">
                            VENDEDOR: {{ strtoupper($vendedor['vendedor_nombre'] ?? 'SIN ASIGNAR') }}
                            <span class="vh-pedidos">({{ $vendedor['total_pedidos'] ?? 0 }} pedidos / facturas pendientes)</span>
                        </td>
                        <td class="vh-total">
                            Pendiente: {{ number_format($vendedor['total_unidades'] ?? 0, 2) }} unds &nbsp;|&nbsp;
                            RD$ {{ number_format($vendedor['total_monto'] ?? 0, 2) }}
                        </td>
                    </tr>
                </table>

                <table class="table" style="margin-bottom: 0;">
                    <thead>
                        <tr>
                            <th style="width: 10%;">CÓDIGO</th>
                            <th style="width: 30%;">PRODUCTO</th>
                            <th style="width: 7%;" class="center">UND</th>
                            <th style="width: 12%;" class="right">CANT. PENDIENTE</th>
                            <th style="width: 13%;" class="right">MONTO RD$</th>
                            <th style="width: 28%;">FACTURAS / CLIENTES DESTINO</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($vendedor['productos'] as $prod)
                            <tr>
                                <td><strong>{{ $prod['codigo'] ?? 'N/A' }}</strong></td>
                                <td>{{ $prod['nombre_completo'] ?? $prod['descripcion'] ?? '' }}</td>
                                <td class="center">{{ $prod['unidad'] ?? 'UND' }}</td>
                                <td class="right">
                                    <span class="badge-qty">{{ number_format($prod['cantidad_pendiente'] ?? 0, 2) }}</span>
                                </td>
                                <td class="right">RD$ {{ number_format($prod['monto_pendiente'] ?? 0, 2) }}</td>
                                <td>
                                    @if(!empty($prod['pedidos']))
                                        @foreach($prod['pedidos'] as $ped)
                                            <span class="detalle-pedido-pill">
                                                {{ !empty($ped['num_factura']) ? '#' . $ped['num_factura'] : 'Ped #' . $ped['pedido_id'] }}
                                                ({{ Str::limit($ped['cliente_nombre'] ?? 'Cliente', 14) }}: {{ number_format($ped['cantidad'] ?? 0, 2) }})
                                            </span>
                                        @endforeach
                                    @else
                                        -
                                    @endif
                                </td>
                            </tr>
                        @empty
                            <tr>
                                <td colspan="6" class="center" style="padding: 10px; color: #64748b;">
                                    Sin productos pendientes para este vendedor.
                                </td>
                            </tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        @empty
            <div style="text-align: center; padding: 30px; color: #64748b; background: #f8fafc; border: 1px dashed #cbd5e1; border-radius: 4px;">
                No se encontraron productos pendientes de entrega para los filtros seleccionados.
            </div>
        @endforelse
    @endif

    <div class="footer">
        Industria California, S.R.L. - Sistema ERP de Control Logístico y Almacén &nbsp;|&nbsp; Documento generado el {{ $fechaGeneracion ?? now()->subHours(4)->format('d/m/Y h:i A') }}
    </div>

</body>
</html>
