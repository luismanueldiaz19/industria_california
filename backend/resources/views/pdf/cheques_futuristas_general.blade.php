<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Reporte de Cheques Futuristas</title>
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
            'title' => 'Reporte de Cheques Futuristas',
            'subtitle' => 'Filtros aplicados'
        ])

        <table class="table">
            <thead>
                <tr>
                    <th style="width: 10%;">FECHA</th>
                    <th style="width: 25%;">CLIENTE</th>
                    <th style="width: 15%;">VENDEDOR</th>
                    <th style="width: 15%;">N° CHEQUE</th>
                    <th style="width: 10%;" class="center">ESTADO</th>
                    <th class="right" style="width: 15%;">MONTO</th>
                </tr>
            </thead>
            <tbody>
                @foreach($cheques as $cheque)
                    <tr>
                        <td>{{ \Carbon\Carbon::parse($cheque->created_at)->format('d/m/Y') }}</td>
                        <td>{{ $cheque->cliente->nombre ?? 'N/A' }}</td>
                        <td>{{ $cheque->vendedor->name ?? 'N/A' }}</td>
                        <td>{{ $cheque->num_cheque ?? 'N/A' }}</td>
                        <td class="center">{{ strtoupper($cheque->estado) }}</td>
                        <td class="right">${{ number_format($cheque->monto, 2) }}</td>
                    </tr>
                @endforeach
                @if($cheques->isEmpty())
                    <tr>
                        <td colspan="6" class="center">No se encontraron cheques con los filtros seleccionados.</td>
                    </tr>
                @endif
            </tbody>
        </table>

        @if($cheques->isNotEmpty())
            <table class="totals">
                <tr class="grand-total">
                    <th>MONTO TOTAL:</th>
                    <td>${{ number_format($totalMonto, 2) }}</td>
                </tr>
            </table>
        @endif

        <div class="footer">
            Generado por Sistema - {{ now()->format('d/m/Y H:i') }}
        </div>
    </div>
</body>
</html>
