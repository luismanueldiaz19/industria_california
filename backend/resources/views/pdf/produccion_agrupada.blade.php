<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Producción Agrupada</title>
    <style>
        @page { margin: 35px 40px; }
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            font-size: 11px;
            color: #1a1a2e;
            margin: 0;
            padding: 0;
        }
        
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
        td { padding: 6px 6px; border-bottom: 1px solid #e8ecf0; vertical-align: middle; }
        .text-right { text-align: right; }
        .text-center { text-align: center; }
        .font-bold { font-weight: bold; }
        .text-orange { color: #f9a825; }
    </style>
</head>
<body>

    @include('components.pdf-header', [
        'title' => 'REPORTE DE PRODUCCIÓN',
        'subtitle' => 'AGRUPADO POR ' . strtoupper($tipo) . (!empty($search) ? " | FILTRO: $search" : '')
    ])

    <table>
        <thead>
            <tr>
                @if($tipo === 'producto')
                    <th>CÓD.</th>
                    <th>PRODUCTO</th>
                    <th>CLIENTE</th>
                    <th class="text-right">CANTIDAD FALTANTE</th>
                @elseif($tipo === 'pedido')
                    <th>PEDIDO ASOCIADO</th>
                    <th>CLIENTE</th>
                    <th class="text-right">ÓRDENES ASOCIADAS</th>
                @elseif($tipo === 'cliente')
                    <th>ID CLIENTE</th>
                    <th>NOMBRE CLIENTE</th>
                    <th class="text-right">ÓRDENES ASOCIADAS</th>
                @elseif($tipo === 'fecha')
                    <th>FECHA DE ENTREGA</th>
                    <th class="text-right">ÓRDENES ASOCIADAS</th>
                @endif
            </tr>
        </thead>
        <tbody>
            @forelse($resultados as $row)
                <tr>
                    @if($tipo === 'producto')
                        <td>{{ $row->producto_codigo ?? 'N/A' }}</td>
                        <td>{{ $row->producto_nombre ?? 'N/A' }}</td>
                        <td>{{ $row->cliente_nombre ?? 'N/A' }}</td>
                        <td class="text-right font-bold text-orange">{{ number_format($row->cantidad_total ?? 0, 1) }}</td>
                    @elseif($tipo === 'pedido')
                        <td class="font-bold">#{{ $row->pedido_id ?? '' }}</td>
                        <td>{{ $row->cliente_nombre ?? 'N/A' }}</td>
                        <td class="text-right">{{ $row->cantidad_ordenes ?? 0 }}</td>
                    @elseif($tipo === 'cliente')
                        <td>{{ $row->cliente_id ?? 'N/A' }}</td>
                        <td>{{ $row->cliente_nombre ?? 'N/A' }}</td>
                        <td class="text-right">{{ $row->cantidad_ordenes ?? 0 }}</td>
                    @elseif($tipo === 'fecha')
                        <td>
                            {{ !empty($row->fecha_estimada_entrega) ? \Carbon\Carbon::parse($row->fecha_estimada_entrega)->format('d/m/Y') : 'Sin Fecha' }}
                        </td>
                        <td class="text-right">{{ $row->cantidad_ordenes ?? 0 }}</td>
                    @endif
                </tr>
            @empty
                <tr>
                    <td colspan="4" class="text-center" style="padding: 20px;">No hay datos para mostrar</td>
                </tr>
            @endforelse
        </tbody>
    </table>

</body>
</html>
