<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Pedido #{{ $pedido->id }}</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            font-size: 12px;
            color: #333;
            margin: 0;
            padding: 0;
        }
        .container {
            width: 100%;
            max-width: 800px;
            margin: 0 auto;
        }

        .info-section {
            width: 100%;
            margin-bottom: 20px;
            border-collapse: collapse;
        }
        .info-section td {
            vertical-align: top;
            width: 50%;
        }
        .info-box {
            border: 1px solid #cbd5e1;
            background-color: #f8fafc;
            padding: 10px 12px;
            border-radius: 6px;
            height: 90px;
            color: #475569;
            line-height: 1.5;
            font-size: 10px;
        }
        .info-box strong {
            display: block;
            margin-bottom: 6px;
            color: #0f172a;
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            border-bottom: 1px solid #e2e8f0;
            padding-bottom: 4px;
        }
        .info-box .label {
            font-weight: bold;
            color: #334155;
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
            font-size: 11px;
        }
        .table td {
            border-bottom: 1px solid #eee;
            padding: 8px;
            font-size: 11px;
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
            font-size: 16px;
            font-weight: bold;
            color: #1976D2;
            border-bottom: 2px solid #1976D2;
            border-top: 2px solid #1976D2;
        }
        .footer {
            clear: both;
            margin-top: 40px;
            text-align: center;
            font-size: 10px;
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
            'title' => 'Pedido #' . $pedido->id,
            'subtitle' => 'Emisión: ' . \Carbon\Carbon::parse($pedido->created_at)->format('d/m/Y H:i') . ' | Estado: ' . strtoupper($pedido->estado)
        ])

        <!-- Info Cliente / Vendedor -->
        <table class="info-section">
            <tr>
                <td style="padding-right: 10px;">
                    <div class="info-box">
                        <strong>Datos del Cliente</strong>
                        <div style="font-size: 11px; font-weight: bold; color: #1e293b; margin-bottom: 4px;">{{ $pedido->cliente->nombre ?? 'N/A' }}</div>
                        <span class="label">RNC:</span> {{ $pedido->cliente->rnc ?? 'N/A' }}<br>
                        <span class="label">Tel:</span> {{ $pedido->cliente->telefono ?? 'N/A' }}<br>
                        <span class="label">Dir:</span> {{ $pedido->cliente->direccion ?? 'N/A' }}
                    </div>
                </td>
                <td style="padding-left: 10px;">
                    <div class="info-box">
                        <strong>Información Adicional</strong>
                        <span class="label">Vendedor:</span> {{ $pedido->vendedor->name ?? 'N/A' }}<br>
                        <span class="label">Ruta:</span> {{ $pedido->ruta->nombre ?? 'N/A' }}<br>
                        <span class="label">Comentario:</span> {{ $pedido->comentario ?? 'Ninguno' }}
                    </div>
                </td>
            </tr>
        </table>

        <!-- Detalles de Productos -->
        <table class="table">
            <thead>
                <tr>
                    <th style="width: 10%;">CÓDIGO</th>
                    <th style="width: 45%;">DESCRIPCIÓN</th>
                    <th class="center" style="width: 15%;">CANT.</th>
                    <th class="right" style="width: 15%;">PRECIO</th>
                    <th class="right" style="width: 15%;">SUBTOTAL</th>
                </tr>
            </thead>
            <tbody>
                @foreach($pedido->detalles as $det)
                <tr>
                    <td>{{ $det->producto->codigo ?? '' }}</td>
                    <td>
                        {{ $det->producto->nombre ?? 'Producto #' . $det->producto_id }}
                        @if($det->observacion)
                            <br><small style="color: #666; font-style: italic;">Nota: {{ $det->observacion }}</small>
                        @endif
                    </td>
                    <td class="center">
                        {{ fmod($det->cantidad, 1) == 0 ? number_format($det->cantidad, 0) : number_format($det->cantidad, 3) }}
                    </td>
                    <td class="right">${{ number_format($det->precio_unitario, 2) }}</td>
                    <td class="right">${{ number_format($det->subtotal, 2) }}</td>
                </tr>
                @endforeach
            </tbody>
        </table>

        <!-- Totales -->
        <table class="totals">
            <tr class="grand-total">
                <th>TOTAL:</th>
                <td>${{ number_format($pedido->total, 2) }}</td>
            </tr>
        </table>

        <!-- Footer -->
        <div class="footer">
            Generado por Sistema Ventas - {{ now()->format('d/m/Y H:i') }}
        </div>
    </div>
</body>
</html>
