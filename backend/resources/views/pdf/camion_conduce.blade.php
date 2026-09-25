<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Conduce de Despacho - Camión #{{ $camion->id }}</title>
    <style>
        @page { margin: 35px 40px; }
        body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            font-size: 11px;
            color: #1a1a2e;
            margin: 0;
            padding: 0;
        }

        .info-grid {
            width: 100%;
            margin-bottom: 20px;
            font-size: 11px;
        }
        .info-grid td { padding: 4px 0; }
        .info-label { font-weight: bold; width: 100px; color: #4a5568; }

        .section-title {
            font-size: 14px;
            font-weight: bold;
            margin-top: 20px;
            margin-bottom: 10px;
            color: #1A1C1E;
            border-bottom: 1px solid #e2e8f0;
            padding-bottom: 5px;
        }

        table.data-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        table.data-table th, table.data-table td {
            border: 1px solid #e2e8f0;
            padding: 6px 8px;
            text-align: left;
        }
        table.data-table th {
            background-color: #1A1C1E;
            color: white;
            font-weight: bold;
        }
        table.data-table td.text-center { text-align: center; }
        table.data-table td.text-right { text-align: right; }
    </style>
</head>
<body>

    <x-pdf-header 
        title="CONDUCE DE DESPACHO" 
        subtitle="Carga de Camión Fisico" 
    />

    <table class="info-grid">
        <tr>
            <td class="info-label">Camión ID:</td>
            <td>#{{ $camion->id }}</td>
            <td class="info-label">Nombre:</td>
            <td>{{ $camion->nombre }}</td>
        </tr>
        <tr>
            <td class="info-label">Chofer:</td>
            <td>{{ optional($camion->chofer->user)->name ?? 'No asignado' }}</td>
            <td class="info-label">Vendedor:</td>
            <td>{{ optional($camion->vendedor)->name ?? 'No asignado' }}</td>
        </tr>
        <tr>
            <td class="info-label">Fecha:</td>
            <td>{{ now()->format('d/m/Y H:i A') }}</td>
            <td class="info-label">Estado:</td>
            <td>{{ strtoupper($camion->estado->value) }}</td>
        </tr>
    </table>

    @php
        $totalesProductos = [];
        $totalBultos = 0;
        
        foreach($camion->pedidos as $pedido) {
            if ($pedido && $pedido->detalles) {
                foreach($pedido->detalles as $detalle) {
                    $prod = $detalle->producto;
                    if (!$prod) continue;
                    
                    $idProd = $prod->id;
                    if (!isset($totalesProductos[$idProd])) {
                        $totalesProductos[$idProd] = [
                            'codigo' => $prod->codigo,
                            'descripcion' => $prod->nombre_completo ?? $prod->descripcion,
                            'unidad' => $prod->unidad,
                            'cantidad' => 0,
                        ];
                    }
                    $totalesProductos[$idProd]['cantidad'] += $detalle->cantidad;
                    $totalBultos += $detalle->cantidad;
                }
            }
        }
        
        usort($totalesProductos, function($a, $b) {
            return strcmp($a['descripcion'], $b['descripcion']);
        });
    @endphp

    <div class="section-title">PRODUCTOS A CARGAR (TOTALIZADO)</div>
    <table class="data-table">
        <thead>
            <tr>
                <th>CÓDIGO</th>
                <th>DESCRIPCIÓN</th>
                <th class="text-center">UNIDAD</th>
                <th class="text-right">CANTIDAD</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($totalesProductos as $item)
                <tr>
                    <td>{{ $item['codigo'] }}</td>
                    <td>{{ $item['descripcion'] }}</td>
                    <td class="text-center">{{ $item['unidad'] ?? 'N/A' }}</td>
                    <td class="text-right"><strong>{{ number_format($item['cantidad'], 0) }}</strong></td>
                </tr>
            @empty
                <tr>
                    <td colspan="4" class="text-center">No hay productos para cargar.</td>
                </tr>
            @endforelse
        </tbody>
        @if(count($totalesProductos) > 0)
        <tfoot>
            <tr>
                <th colspan="3" class="text-right" style="background-color: #f8fafc; color: #1a1a2e;">TOTAL UNIDADES:</th>
                <th class="text-right" style="background-color: #f8fafc; color: #1a1a2e; font-size: 12px;">{{ number_format($totalBultos, 0) }}</th>
            </tr>
        </tfoot>
        @endif
    </table>

    <div class="section-title">PEDIDOS EN EL CAMIÓN</div>
    <table class="data-table">
        <thead>
            <tr>
                <th style="width: 50px;">ORDEN</th>
                <th style="width: 80px;">PEDIDO #</th>
                <th>CLIENTE</th>
                <th>DIRECCIÓN</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($camion->pedidos as $pedido)
                <tr>
                    <td class="text-center">{{ $pedido->pivot->orden_viaje ?? '-' }}</td>
                    <td class="text-center">{{ $pedido->id }}</td>
                    <td>{{ optional($pedido->cliente)->nombre ?? 'Cliente no encontrado' }}</td>
                    <td>{{ optional($pedido->cliente)->direccion ?? '-' }}</td>
                </tr>
            @empty
                <tr>
                    <td colspan="4" class="text-center">No hay pedidos asignados.</td>
                </tr>
            @endforelse
        </tbody>
    </table>

    <div style="margin-top: 50px; width: 100%;">
        <table style="width: 100%; text-align: center; border: none;">
            <tr>
                <td style="width: 33%; border: none;">
                    <div style="border-top: 1px solid #000; width: 80%; margin: 0 auto; padding-top: 5px;">
                        Despachado por (Almacén)
                    </div>
                </td>
                <td style="width: 33%; border: none;">
                    <div style="border-top: 1px solid #000; width: 80%; margin: 0 auto; padding-top: 5px;">
                        Recibido por (Chofer)
                    </div>
                </td>
                <td style="width: 33%; border: none;">
                    <div style="border-top: 1px solid #000; width: 80%; margin: 0 auto; padding-top: 5px;">
                        Auditor / Seguridad
                    </div>
                </td>
            </tr>
        </table>
    </div>

</body>
</html>
