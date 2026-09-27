<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Estadísticas de Gastos y Combustible</title>
    <style>
        @page { margin: 40px; }
        body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; font-size: 14px; color: #333; margin: 0; padding: 0; }

        table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 11px; }
        table, th, td { border: 1px solid #ddd; }
        th, td { padding: 4px; text-align: left; }
        th { background-color: #f4f4f4; }
        .text-right { text-align: right; }
        .font-bold { font-weight: bold; }
        .total-row { background-color: #f8f9fa; font-weight: bold; }
        .gran-total { color: #E31E24; }
    </style>
</head>
<body>
    @include('components.pdf-header', [
        'title' => 'Flota Vehicular', 
        'subtitle' => 'Estadísticas de Gastos y Combustible - ' . $year
    ])
    
    <div style="margin-bottom: 20px;">
        <h3 style="margin: 0; font-size: 14px; color: #444;">Total {{ $year }}: <span class="gran-total">${{ number_format($totalYear, 2) }}</span></h3>
    </div>

    @php
        $meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    @endphp

    <h4 style="margin: 5px 0; font-size: 13px; color: #444;">Gasto por Vehículo</h4>
    <table>
        <thead>
            <tr>
                <th>Item</th>
                @foreach($meses as $mes)
                    <th class="text-right">{{ $mes }}</th>
                @endforeach
                <th class="text-right">Total</th>
            </tr>
        </thead>
        <tbody>
            @php
                $totalesMesVehiculo = array_fill(1, 12, 0.0);
                $granTotalVehiculo = 0.0;
            @endphp
            @foreach($porVehiculo as $ficha => $mesesData)
                <tr>
                    <td class="font-bold">{{ $ficha }}</td>
                    @php $rowTotal = 0; @endphp
                    @for($i = 1; $i <= 12; $i++)
                        @php 
                            $val = $mesesData[$i] ?? 0.0; 
                            $rowTotal += $val;
                            $totalesMesVehiculo[$i] += $val;
                            $granTotalVehiculo += $val;
                        @endphp
                        <td class="text-right">{{ $val > 0 ? number_format($val, 2) : '0.00' }}</td>
                    @endfor
                    <td class="text-right font-bold">{{ number_format($rowTotal, 2) }}</td>
                </tr>
            @endforeach
            <tr class="total-row">
                <td>Total general</td>
                @for($i = 1; $i <= 12; $i++)
                    <td class="text-right">{{ number_format($totalesMesVehiculo[$i], 2) }}</td>
                @endfor
                <td class="text-right gran-total">{{ number_format($granTotalVehiculo, 2) }}</td>
            </tr>
        </tbody>
    </table>

    <br><br>

    <h4 style="margin: 5px 0; font-size: 13px; color: #444;">Gasto por Tipo</h4>
    <table>
        <thead>
            <tr>
                <th>Item</th>
                @foreach($meses as $mes)
                    <th class="text-right">{{ $mes }}</th>
                @endforeach
                <th class="text-right">Total</th>
            </tr>
        </thead>
        <tbody>
            @php
                $totalesMesTipo = array_fill(1, 12, 0.0);
                $granTotalTipo = 0.0;
            @endphp
            @foreach($porTipo as $tipo => $mesesData)
                <tr>
                    <td class="font-bold">{{ $tipo }}</td>
                    @php $rowTotal = 0; @endphp
                    @for($i = 1; $i <= 12; $i++)
                        @php 
                            $val = $mesesData[$i] ?? 0.0; 
                            $rowTotal += $val;
                            $totalesMesTipo[$i] += $val;
                            $granTotalTipo += $val;
                        @endphp
                        <td class="text-right">{{ $val > 0 ? number_format($val, 2) : '0.00' }}</td>
                    @endfor
                    <td class="text-right font-bold">{{ number_format($rowTotal, 2) }}</td>
                </tr>
            @endforeach
            <tr class="total-row">
                <td>Total general</td>
                @for($i = 1; $i <= 12; $i++)
                    <td class="text-right">{{ number_format($totalesMesTipo[$i], 2) }}</td>
                @endfor
                <td class="text-right gran-total">{{ number_format($granTotalTipo, 2) }}</td>
            </tr>
        </tbody>
    </table>
</body>
</html>
