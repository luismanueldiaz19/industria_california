<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Inventario</title>
    <style>
        @page { margin: 35px 40px; }
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            font-size: 11px;
            color: #1a1a2e;
            margin: 0;
            padding: 0;
        }

        /* ── Tabla principal ── */
        table { width: 100%; border-collapse: collapse; margin-top: 12px; font-size: 10px; }
        thead th {
            background-color: #1A1C1E;
            color: #ffffff;
            padding: 7px 6px;
            text-align: left;
            font-weight: bold;
            letter-spacing: 0.3px;
            text-transform: uppercase;
            font-size: 9px;
        }
        tbody tr:nth-child(even) { background-color: #f8f9fb; }
        tbody tr:hover { background-color: #f0f4ff; }
        td { padding: 6px 6px; border-bottom: 1px solid #e8ecf0; vertical-align: middle; }

        /* ── Badges de estado ── */
        .badge {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 10px;
            font-size: 8.5px;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 0.4px;
        }
        .badge-ok       { background-color: #e6f4ea; color: #1e8e3e; border: 1px solid #1e8e3e; }
        .badge-alerta   { background-color: #fef7e0; color: #c97a00; border: 1px solid #f9a825; }
        .badge-critico  { background-color: #fce8e6; color: #c5221f; border: 1px solid #ea4335; }
        .badge-negativo { background-color: #2c2f33; color: #ffffff; border: 1px solid #E31E24; }

        /* ── Totales ── */
        .totales-row td {
            background-color: #1A1C1E;
            color: #ffffff;
            font-weight: bold;
            font-size: 10px;
            padding: 8px 6px;
            border: none;
        }

        /* ── Resumen estadístico ── */
        .stats-grid {
            display: table;
            width: 100%;
            margin-bottom: 16px;
            border-collapse: collapse;
        }
        .stat-box {
            display: table-cell;
            width: 25%;
            text-align: center;
            padding: 10px 6px;
            border: 1px solid #e2e8f0;
            background-color: #f8f9fb;
        }
        .stat-box .stat-value {
            font-size: 18px;
            font-weight: bold;
            color: #1A1C1E;
            display: block;
        }
        .stat-box .stat-label {
            font-size: 8px;
            color: #64748b;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            display: block;
            margin-top: 2px;
        }
        .stat-box.red .stat-value  { color: #E31E24; }
        .stat-box.warn .stat-value { color: #c97a00; }
        .stat-box.ok .stat-value   { color: #1e8e3e; }

        .text-right { text-align: right; }
        .text-center { text-align: center; }
        .monospace { font-family: 'Courier New', monospace; font-size: 9px; }
    </style>
</head>
<body>
    <x-pdf-header title="Inventario de Productos" subtitle="Reporte General de Stock" />

    @php
        $totalProductos  = $productos->count();
        $enOk     = $productos->filter(fn($p) => $p->estado_stock === 'ok')->count();
        $enAlerta = $productos->filter(fn($p) => $p->estado_stock === 'alerta')->count();
        $criticos = $productos->filter(fn($p) => $p->estado_stock === 'critico' || $p->estado_stock === 'negativo')->count();
        $valorInventario = $productos->sum(fn($p) => max(0, (float)$p->stock) * (float)$p->costo);
    @endphp

    {{-- Resumen estadístico --}}
    <div class="stats-grid">
        <div class="stat-box">
            <span class="stat-value">{{ $totalProductos }}</span>
            <span class="stat-label">Total Productos</span>
        </div>
        <div class="stat-box ok">
            <span class="stat-value">{{ $enOk }}</span>
            <span class="stat-label">Stock OK</span>
        </div>
        <div class="stat-box warn">
            <span class="stat-value">{{ $enAlerta }}</span>
            <span class="stat-label">En Alerta</span>
        </div>
        <div class="stat-box red">
            <span class="stat-value">{{ $criticos }}</span>
            <span class="stat-label">Críticos / Negativos</span>
        </div>
    </div>

    <table>
        <thead>
            <tr>
                <th style="width:10%">Código</th>
                <th style="width:28%">Nombre</th>
                <th style="width:8%">Unidad</th>
                <th style="width:14%">Categoría</th>
                <th style="text-align:right; width:10%">Stock</th>
                <th style="text-align:right; width:9%">Mín</th>
                <th style="text-align:right; width:9%">Máx</th>
                <th style="text-align:right; width:9%">Costo</th>
                <th style="text-align:right; width:9%">Venta</th>
                <th style="text-align:center; width:11%">Estado</th>
            </tr>
        </thead>
        <tbody>
            @php $totalStock = 0; @endphp
            @forelse($productos as $p)
                @php
                    $totalStock += (float)$p->stock;
                    $estado = $p->estado_stock;
                    $badgeClass = match($estado) {
                        'ok'       => 'badge-ok',
                        'alerta'   => 'badge-alerta',
                        'critico'  => 'badge-critico',
                        'negativo' => 'badge-negativo',
                        default    => 'badge-critico',
                    };
                    $estadoLabel = match($estado) {
                        'ok'       => 'OK',
                        'alerta'   => 'ALERTA',
                        'critico'  => 'CRÍTICO',
                        'negativo' => 'NEGATIVO',
                        default    => '—',
                    };
                @endphp
                <tr>
                    <td class="monospace">{{ $p->codigo }}</td>
                    <td style="font-weight:600">{{ $p->nombre }}</td>
                    <td class="text-center">{{ $p->unidad }}</td>
                    <td>{{ $p->categoria?->nombre ?? '—' }}</td>
                    <td class="text-right" style="{{ (float)$p->stock < 0 ? 'color:#E31E24; font-weight:bold;' : '' }}">
                        {{ number_format((float)$p->stock, 2) }}
                    </td>
                    <td class="text-right" style="color:#64748b">
                        {{ $p->stock_minimo !== null ? number_format((float)$p->stock_minimo, 2) : '—' }}
                    </td>
                    <td class="text-right" style="color:#64748b">
                        {{ $p->stock_maximo !== null ? number_format((float)$p->stock_maximo, 2) : '—' }}
                    </td>
                    <td class="text-right">${{ number_format((float)$p->costo, 2) }}</td>
                    <td class="text-right">${{ number_format((float)$p->venta, 2) }}</td>
                    <td class="text-center">
                        <span class="badge {{ $badgeClass }}">{{ $estadoLabel }}</span>
                    </td>
                </tr>
            @empty
                <tr>
                    <td colspan="10" class="text-center" style="padding:20px; color:#64748b;">
                        No hay productos en el inventario.
                    </td>
                </tr>
            @endforelse
            <tr class="totales-row">
                <td colspan="4" style="text-align:right; color:#aab4c0;">TOTALES:</td>
                <td class="text-right">{{ number_format($totalStock, 2) }}</td>
                <td colspan="3"></td>
                <td colspan="2" style="text-align:right; color:#aab4c0; font-size:9px;">
                    Valor inventario: ${{ number_format($valorInventario, 2) }}
                </td>
            </tr>
        </tbody>
    </table>

    <p style="margin-top:14px; font-size:8.5px; color:#94a3b8; text-align:right;">
        Generado el {{ \Carbon\Carbon::now()->subHours(4)->format('d/m/Y H:i') }} AST
        &nbsp;|&nbsp; Total de registros: {{ $totalProductos }}
    </p>
</body>
</html>
