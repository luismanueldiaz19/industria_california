<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Movimientos de Inventario</title>
    <style>
        @page { margin: 35px 40px; size: A4 landscape; }
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            font-size: 10px;
            color: #1a1a2e;
            margin: 0;
            padding: 0;
        }

        table { width: 100%; border-collapse: collapse; margin-top: 12px; font-size: 9px; }
        thead th {
            background-color: #1A1C1E;
            color: #ffffff;
            padding: 6px 5px;
            text-align: left;
            font-size: 8.5px;
            text-transform: uppercase;
            letter-spacing: 0.3px;
        }
        tbody tr:nth-child(even) { background-color: #f8f9fb; }
        td { padding: 5px; border-bottom: 1px solid #e8ecf0; vertical-align: middle; }

        /* Tipo badges */
        .badge {
            display: inline-block;
            padding: 2px 6px;
            border-radius: 8px;
            font-size: 8px;
            font-weight: bold;
            text-transform: uppercase;
        }
        .tipo-AJUSTE     { background-color: #e8f0fe; color: #1a73e8; border: 1px solid #1a73e8; }
        .tipo-PRODUCCION { background-color: #e6f4ea; color: #1e8e3e; border: 1px solid #1e8e3e; }
        .tipo-VENTA      { background-color: #fce8e6; color: #c5221f; border: 1px solid #ea4335; }
        .tipo-BAJA       { background-color: #3c3c3c; color: #ffffff; border: 1px solid #666; }

        .positivo { color: #1e8e3e; font-weight: bold; }
        .negativo { color: #E31E24; font-weight: bold; }

        .totales-row td {
            background-color: #1A1C1E;
            color: #fff;
            font-weight: bold;
            padding: 7px 5px;
            border: none;
            font-size: 9px;
        }
        .text-right  { text-align: right; }
        .text-center { text-align: center; }
        .monospace { font-family: 'Courier New', monospace; }
    </style>
</head>
<body>
    <x-pdf-header title="Movimientos de Inventario" subtitle="Historial de entradas y salidas de stock" />

    {{-- Resumen por Tipo --}}
    @if(isset($resumen) && count($resumen) > 0)
    <table style="margin-bottom:12px; font-size:10px;">
        <tr>
            @foreach($resumen as $tipo => $total)
            @php
                $bg = '#1A1C1E';
                $border = '#555';
                $color = '#ffffff';
                if ($tipo == 'PRODUCCION') { $bg = '#e6f4ea'; $border = '#1e8e3e'; $color = '#1e8e3e'; }
                if ($tipo == 'VENTA') { $bg = '#fce8e6'; $border = '#ea4335'; $color = '#E31E24'; }
                if ($tipo == 'AJUSTE') { $bg = '#e8f0fe'; $border = '#1a73e8'; $color = '#1a73e8'; }
                if ($tipo == 'BAJA') { $bg = '#fff3e0'; $border = '#ff9800'; $color = '#e65100'; }
            @endphp
            <td style="width:{{ 100/count($resumen) }}%; text-align:center; padding:8px; background:{{ $bg }}; border:1px solid {{ $border }};">
                <strong style="font-size:14px; color:{{ $color }};">{{ $total > 0 ? '+' : '' }}{{ number_format((float)$total, 2) }}</strong><br>
                <span style="font-size:8px; color:#555;">{{ $tipo }}</span>
            </td>
            @endforeach
        </tr>
    </table>
    @endif

    <table>
        <thead>
            <tr>
                <th style="width:12%">Fecha</th>
                <th style="width:10%">Código</th>
                <th style="width:22%">Producto</th>
                <th style="width:10%;text-align:center">Tipo</th>
                <th style="width:8%;text-align:center">Subtipo</th>
                <th style="width:10%;text-align:right">Cantidad</th>
                <th style="width:10%;text-align:right">Stock Ant.</th>
                <th style="width:10%;text-align:right">Stock Res.</th>
                <th style="width:12%">Usuario</th>
                <th style="width:16%">Nota</th>
            </tr>
        </thead>
        <tbody>
            @forelse($movimientos as $mov)
                @php
                    $esEntrada = (float)$mov->cantidad > 0;
                    $fecha     = \Carbon\Carbon::parse($mov->created_at)->subHours(4)->format('d/m/Y H:i');
                @endphp
                <tr>
                    <td class="monospace">{{ $fecha }}</td>
                    <td class="monospace">{{ $mov->producto?->codigo ?? '—' }}</td>
                    <td style="font-weight:600">{{ $mov->producto?->nombre ?? '—' }}</td>
                    <td class="text-center">
                        <span class="badge tipo-{{ $mov->tipo }}">{{ $mov->tipo }}</span>
                    </td>
                    <td class="text-center" style="color:#64748b; font-size:8px;">
                        {{ $mov->subtipo ?? '—' }}
                    </td>
                    <td class="text-right {{ $esEntrada ? 'positivo' : 'negativo' }}">
                        {{ $esEntrada ? '+' : '' }}{{ number_format((float)$mov->cantidad, 2) }}
                    </td>
                    <td class="text-right" style="color:#64748b;">
                        {{ number_format((float)$mov->stock_anterior, 2) }}
                    </td>
                    <td class="text-right" style="{{ (float)$mov->stock_resultante < 0 ? 'color:#E31E24; font-weight:bold;' : '' }}">
                        {{ number_format((float)$mov->stock_resultante, 2) }}
                    </td>
                    <td>{{ $mov->user?->name ?? '—' }}</td>
                    <td style="color:#64748b; font-size:8px;">{{ $mov->nota ?? '—' }}</td>
                </tr>
            @empty
                <tr>
                    <td colspan="10" class="text-center" style="padding:20px; color:#64748b;">
                        No hay movimientos registrados.
                    </td>
                </tr>
            @endforelse

        </tbody>
    </table>

    <p style="margin-top:12px; font-size:8px; color:#94a3b8; text-align:right;">
        Generado el {{ \Carbon\Carbon::now()->subHours(4)->format('d/m/Y H:i') }} AST
        &nbsp;|&nbsp; Total registros: {{ $movimientos->count() }}
    </p>
</body>
</html>
