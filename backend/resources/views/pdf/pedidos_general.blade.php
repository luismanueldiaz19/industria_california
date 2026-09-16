<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte General de Pedidos</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            font-size: 11px;
            color: #333;
            margin: 0;
            padding: 0;
        }
        .container {
            width: 100%;
            max-width: 1000px;
            margin: 0 auto;
        }
        .table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        .table th {
            background-color: #1E2F4C;
            color: #fff;
            padding: 8px;
            text-align: left;
            font-size: 10px;
            text-transform: uppercase;
        }
        .table td {
            border-bottom: 1px solid #eee;
            padding: 6px 8px;
            font-size: 10px;
        }
        .table th.right, .table td.right {
            text-align: right;
        }
        .table th.center, .table td.center {
            text-align: center;
        }
        .totals {
            width: 40%;
            float: right;
            border-collapse: collapse;
        }
        .totals th, .totals td {
            padding: 8px;
            text-align: right;
            border-bottom: 1px solid #ddd;
        }
        .totals th {
            background-color: #f9f9f9;
            color: #1E2F4C;
        }
        .totals .grand-total th, .totals .grand-total td {
            font-size: 14px;
            font-weight: bold;
            color: #1976D2;
            border-bottom: 2px solid #1976D2;
            border-top: 2px solid #1976D2;
        }
        .footer {
            clear: both;
            margin-top: 40px;
            text-align: center;
            font-size: 9px;
            color: #777;
            border-top: 1px solid #ddd;
            padding-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        @include('components.pdf-header', [
            'title' => 'Reporte General de Pedidos',
            'subtitle' => 'Período: ' . ($fechaInicio ?? 'Inicio') . ' al ' . ($fechaFin ?? 'Fin')
        ])

        <table class="table">
            <thead>
                <tr>
                    <th style="width: 6%;">ID</th>
                    <th style="width: 12%;">FECHA</th>
                    <th style="width: 20%;">CLIENTE</th>
                    <th style="width: 15%;">VENDEDOR</th>
                    <th style="width: 11%;" class="center">ESTADO</th>
                    <th class="right" style="width: 12%;">T. ORIG</th>
                    <th class="right" style="width: 12%;">FALTANTE</th>
                    <th class="right" style="width: 12%;">REAL</th>
                </tr>
            </thead>
            <tbody>
                @php 
                    $granTotalOriginal = 0; 
                    $granTotalFaltante = 0;
                    $granTotalReal = 0;
                @endphp
                @foreach($pedidos as $pedido)
                    @php 
                        $totalOriginal = $pedido->total;
                        $faltante = 0;
                        if($pedido->detalles) {
                            foreach($pedido->detalles as $det) {
                                $faltante += ($det->cantidad_en_produccion * $det->precio_unitario);
                            }
                        }
                        $totalReal = $totalOriginal - $faltante;

                        $granTotalOriginal += $totalOriginal;
                        $granTotalFaltante += $faltante;
                        $granTotalReal += $totalReal;
                    @endphp
                    <tr>
                        <td>#{{ $pedido->id }}</td>
                        <td>{{ \Carbon\Carbon::parse($pedido->created_at)->format('d/m/Y H:i') }}</td>
                        <td>{{ $pedido->cliente->nombre ?? 'N/A' }}</td>
                        <td>{{ $pedido->vendedor->name ?? 'N/A' }}</td>
                        <td class="center">{{ strtoupper($pedido->estado) }}</td>
                        <td class="right">${{ number_format($totalOriginal, 2) }}</td>
                        <td class="right" style="color: {{ $faltante > 0 ? '#d32f2f' : 'inherit' }}">${{ number_format($faltante, 2) }}</td>
                        <td class="right" style="font-weight: bold;">${{ number_format($totalReal, 2) }}</td>
                    </tr>
                @endforeach
                @if($pedidos->isEmpty())
                    <tr>
                        <td colspan="8" class="center">No se encontraron pedidos en el rango seleccionado.</td>
                    </tr>
                @endif
            </tbody>
        </table>

        @if($pedidos->isNotEmpty())
            <table class="totals">
                <tr>
                    <th>TOTAL ORIGINAL:</th>
                    <td>${{ number_format($granTotalOriginal, 2) }}</td>
                </tr>
                <tr>
                    <th>TOTAL FALTANTES:</th>
                    <td style="color: #d32f2f;">${{ number_format($granTotalFaltante, 2) }}</td>
                </tr>
                <tr class="grand-total">
                    <th>TOTAL REAL:</th>
                    <td>${{ number_format($granTotalReal, 2) }}</td>
                </tr>
            </table>
        @endif

        <div class="footer">
            Generado por Sistema Ventas - {{ now()->format('d/m/Y H:i') }}
        </div>
    </div>
</body>
</html>
